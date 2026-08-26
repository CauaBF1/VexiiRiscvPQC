#!/usr/bin/env bash
# Deploy do ML-KEM-512 no BIOS do LiteX + build/load para Sipeed Tang Primer 20K
# com CPU VexiiRiscv. Pensado para rodar no computador onde a placa está conectada,
# logo após um `git pull` deste repositório.
#
# Uso:
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh            # instala + build + load
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --check    # só valida o ambiente
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --install  # só instala no BIOS
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --build    # instala + build (sem gravar)
#
# Variáveis (todas com default):
#   LITEX_DIR      raiz do LiteX já clonado (contém litex/, litex-boards/, ...). default: ~/litex
#   CPU_VARIANT    variant do VexiiRiscv no LiteX. default: standard
#   VEXII_ARGS     flags extras para o gerador do core. default: vazio
#   UART_DEV       porta serial do vlab para o litex_term. default: /dev/ttyUSB2
set -euo pipefail

ACTION="${1:---all}"                                  # --check | --install | --build | --all
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$REPO_ROOT/litex/tang_primer_20k"
LITEX_DIR="${LITEX_DIR:-$HOME/litex}"
CPU_VARIANT="${CPU_VARIANT:-standard}"
VEXII_ARGS="${VEXII_ARGS:-}"
UART_DEV="${UART_DEV:-/dev/ttyUSB2}"
MLKEM_DIR="$REPO_ROOT/src/main/c/vexii/mlkem512"
MLKEM_PATCH="$REPO_ROOT/external/mlkem-native.patch"
MLKEM_NATIVE_ROOT="$REPO_ROOT/external/mlkem-native"

case "$ACTION" in
  --check|--install|--build|--all) ;;
  *) printf 'ERRO: ação desconhecida: %s (use --check, --install, --build ou --all)\n' "$ACTION" >&2; exit 2 ;;
esac

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mERRO: %s\033[0m\n' "$*" >&2; exit 1; }

repo_revision() {
  local path="$1" top
  top="$(git -C "$(dirname "$path")" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$top" ]; then
    printf '%s @ %s\n' "$top" "$(git -C "$top" rev-parse --short=12 HEAD)"
  else
    printf 'sem repositório Git detectado para %s\n' "$path"
  fi
}

preflight() {
  local core_py board_target patch_state legacy_line python_version meson_version ninja_version

  [ -d "$LITEX_DIR" ] || die "LITEX_DIR não existe: $LITEX_DIR"
  [ -f "$MLKEM_NATIVE_ROOT/mlkem/mlkem_native.c" ] \
    || die "submódulo mlkem-native ausente; rode: git submodule update --init external/mlkem-native"
  [ -f "$MLKEM_PATCH" ] || die "patch ML-KEM ausente: $MLKEM_PATCH"

  command -v meson >/dev/null 2>&1 || die "Meson ausente no ambiente ativo (instale meson no venv do LiteX)"
  command -v ninja >/dev/null 2>&1 || die "Ninja ausente no ambiente ativo (instale ninja no venv do LiteX)"
  (cd / && python3 -c 'import litex, litex_boards') >/dev/null 2>&1 \
    || die "python3 não importa litex e litex_boards; ative o ambiente LiteX correto"

  BIOS_DIR="$(find "$LITEX_DIR" -type f -path '*/soc/software/bios/main.c' -printf '%h\n' -quit 2>/dev/null)"
  [ -n "$BIOS_DIR" ] || die "BIOS do LiteX não encontrado sob $LITEX_DIR"

  core_py="$(find "$LITEX_DIR" -type f -path '*/soc/cores/cpu/vexiiriscv/core.py' -print -quit 2>/dev/null)"
  [ -n "$core_py" ] || die "core.py do VexiiRiscv não encontrado sob $LITEX_DIR"
  legacy_line="$(grep -En -m1 '^[[:space:]]*[^#].*--with-(mul|div)' "$core_py" || true)"
  if [ -n "$legacy_line" ]; then
    die "core.py ainda injeta flag legada: $core_py ($legacy_line; aplique o Patch 1 documentado no README)"
  fi

  board_target="$(cd / && python3 -c 'import inspect, litex_boards.targets.sipeed_tang_primer_20k as m; print(inspect.getsourcefile(m))' 2>/dev/null || true)"
  [ -n "$board_target" ] && [ -f "$board_target" ] \
    || die "target sipeed_tang_primer_20k não foi localizado no ambiente Python ativo"
  if grep -Eq '^[[:space:]]*self\.specials \+= AsyncResetSynchronizer\(self\.cd_sys, ~pll\.locked \| self\.rst \| self\.reset\)' "$board_target"; then
    die "target ainda contém o segundo driver de sys_rst: $board_target (aplique o Patch 3 documentado no README)"
  fi

  if git -C "$MLKEM_NATIVE_ROOT" apply --reverse --check "$MLKEM_PATCH" 2>/dev/null; then
    patch_state="aplicado"
  elif git -C "$MLKEM_NATIVE_ROOT" apply --check "$MLKEM_PATCH" 2>/dev/null; then
    patch_state="pronto para aplicar"
  else
    die "external/mlkem-native não está limpo nem corresponde ao patch versionado"
  fi

  python_version="$(python3 -c 'import platform; print(platform.python_version())')"
  meson_version="$(meson --version 2>&1)"
  ninja_version="$(ninja --version 2>&1)"
  [ -n "$meson_version" ] || meson_version="disponível (versão não informada)"
  [ -n "$ninja_version" ] || ninja_version="disponível (versão não informada)"

  say "Preflight concluído"
  echo "    BIOS: $BIOS_DIR"
  echo "    Vexii core.py: $core_py"
  echo "    target da placa: $board_target"
  echo "    patch mlkem-native: $patch_state"
  echo "    ferramentas: Python $python_version, Meson $meson_version, Ninja $ninja_version"
  echo "    LiteX: $(repo_revision "$core_py")"
  echo "    LiteX-Boards: $(repo_revision "$board_target")"
}

# --- 1. garantir e validar todo o ambiente antes de alterar o BIOS ---
if [ ! -f "$MLKEM_NATIVE_ROOT/mlkem/mlkem_native.c" ] && [ "$ACTION" != "--check" ]; then
  say "Inicializando external/mlkem-native"
  git -C "$REPO_ROOT" submodule update --init external/mlkem-native
fi

preflight
[ "$ACTION" = "--check" ] && exit 0

say "Aplicando o patch versionado do mlkem-native"
make -C "$MLKEM_DIR" prep

# --- 2. localizar o BIOS do LiteX ---
say "BIOS do LiteX: $BIOS_DIR"

# --- 3. copiar os arquivos de integração (agnósticos de CPU) ---
say "Copiando arquivos ML-KEM para o BIOS"
cp "$PKG_DIR/bios/mlkem_litex.c"               "$BIOS_DIR/"
cp "$PKG_DIR/bios/mlkem_native_litex_config.h" "$BIOS_DIR/"
cp "$PKG_DIR/bios/kat_vectors.h"               "$BIOS_DIR/"

# --- 4. patch idempotente do Makefile do BIOS ---
# Diferente da referência (que aninhava o LiteX dentro do projeto), aqui o LiteX
# está separado, então o caminho do mlkem-native é injetado explicitamente.
MK="$BIOS_DIR/Makefile"
[ -f "$MK" ] || die "Makefile do BIOS não encontrado: $MK"
if ! grep -q 'MLKEM_NATIVE_DIR' "$MK"; then
  say "Aplicando patch no Makefile do BIOS (backup em Makefile.pre-mlkem)"
  cp "$MK" "$MK.pre-mlkem"
  MLKEM_NATIVE_DIR="$REPO_ROOT/external/mlkem-native/mlkem"
  # 4a. bloco de include + caminho (após o include do common.mak)
  awk -v dir="$MLKEM_NATIVE_DIR" '
    { print }
    /software\/common.mak/ && !done {
      print ""
      print "# >>> mlkem-native integration >>>"
      print "MLKEM_NATIVE_DIR ?= " dir
      print "CFLAGS += -I$(BIOS_DIRECTORY) -I$(MLKEM_NATIVE_DIR) -DMLK_CONFIG_FILE=\x27\"mlkem_native_litex_config.h\"\x27"
      print "VPATH := $(VPATH):$(MLKEM_NATIVE_DIR)"
      print "vpath %.c $(MLKEM_NATIVE_DIR)"
      print "# <<< mlkem-native integration <<<"
      done=1
    }
  ' "$MK.pre-mlkem" > "$MK"
  # 4b. adicionar os objetos ML-KEM à lista OBJECTS (antes de crt0.o)
  sed -i 's/^\([[:space:]]*\)crt0\.o/\1mlkem_litex.o \\\n\1mlkem_native.o \\\n\1crt0.o/' "$MK"
  grep -q 'mlkem_litex.o' "$MK" || die "falha ao inserir objetos ML-KEM no Makefile; edite manualmente"
else
  say "Makefile do BIOS já contém a integração ML-KEM (pulando)"
fi

# --- 5. patch idempotente do main.c (chamada no boot) ---
MAIN="$BIOS_DIR/main.c"
if ! grep -q 'litex_mlkem_kat_status' "$MAIN"; then
  say "Aplicando patch no main.c do BIOS (backup em main.c.pre-mlkem)"
  cp "$MAIN" "$MAIN.pre-mlkem"
  # declaração após o primeiro include local
  sed -i '0,/#include "/{s//int litex_mlkem_kat_status(void);\n#include "/}' "$MAIN"
  # chamada logo após uart_init();
  sed -i 's/\([[:space:]]*\)uart_init();/\1uart_init();\n\t(void)litex_mlkem_kat_status();/' "$MAIN"
  grep -q 'litex_mlkem_kat_status' "$MAIN" || die "falha ao inserir a chamada no main.c; edite manualmente"
else
  say "main.c do BIOS já chama o ML-KEM (pulando)"
fi

[ "$ACTION" = "--install" ] && { say "Instalação concluída (sem build)."; exit 0; }

# --- 6. build (+ load) do bitstream para a Tang Primer 20K ---
BUILD_FLAGS=(--build)
[ "$ACTION" = "--all" ] && BUILD_FLAGS+=(--load)
VEXII_FLAGS=()
[ -n "$VEXII_ARGS" ] && VEXII_FLAGS+=(--vexii-args="$VEXII_ARGS")
say "Gerando SoC VexiiRiscv para Tang Primer 20K (${BUILD_FLAGS[*]})"
echo "    (LiteX chama internamente: sbt runMain vexiiriscv.soc.litex.SocGen ...)"
export MLKEM_REPO_DIR="$REPO_ROOT"
cd "$LITEX_DIR"
python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv \
  --cpu-variant="$CPU_VARIANT" \
  "${VEXII_FLAGS[@]}" \
  --uart-name=serial \
  --bios-console=disable \
  --bios-lto \
  --integrated-rom-size=0x8000 \
  --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  "${BUILD_FLAGS[@]}"

say "Pronto. Para ler a UART:"
echo "    python3 -m litex.tools.litex_term $UART_DEV --speed 115200"
echo "    # se corromper:  python3 -m serial.tools.miniterm $UART_DEV 115200 --raw"
