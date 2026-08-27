#!/usr/bin/env bash
# Deploy reproducível do ML-KEM-512 no BIOS LiteX da Sipeed Tang Primer 20K.
# O hardware e o firmware Montgomery podem ser selecionados separadamente, mas
# o firmware nunca pode emitir uma instrução ausente no core.
#
# Exemplos:
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --patch-litex
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --check
#   MLKEM_ACCEL=montmul LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
#   MLKEM_HW=both MLKEM_SW=montred LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
set -euo pipefail

ACTION="${1:---all}" # --patch-litex | --check | --install | --build | --all
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$REPO_ROOT/litex/tang_primer_20k"
LITEX_DIR="${LITEX_DIR:-$HOME/litex}"
CPU_VARIANT="${CPU_VARIANT:-standard}"
VEXII_ARGS="${VEXII_ARGS:-}"
UART_DEV="${UART_DEV:-/dev/ttyUSB2}"
MLKEM_DIR="$REPO_ROOT/src/main/c/vexii/mlkem512"
MLKEM_PATCH="$REPO_ROOT/external/mlkem-native.patch"
MLKEM_NATIVE_ROOT="$REPO_ROOT/external/mlkem-native"
LITEX_GENERATOR_PATCH="$PKG_DIR/patches/vexiiriscv_local_generator.patch"
LITEX_EXPECTED_REV_PREFIX="97d81467881f"

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mERRO: %s\033[0m\n' "$*" >&2; exit 1; }

case "$ACTION" in
  --patch-litex|--check|--install|--build|--all) ;;
  *) die "ação desconhecida: $ACTION (use --patch-litex, --check, --install, --build ou --all)" ;;
esac

resolve_accel_config() {
  local accel_was_set=0 hw_was_set=0 sw_was_set=0 selected
  [ "${MLKEM_ACCEL+x}" = x ] && accel_was_set=1
  [ "${MLKEM_HW+x}" = x ] && hw_was_set=1
  [ "${MLKEM_SW+x}" = x ] && sw_was_set=1

  if [ "$accel_was_set" -eq 1 ] && { [ "$hw_was_set" -eq 1 ] || [ "$sw_was_set" -eq 1 ]; }; then
    die "use MLKEM_ACCEL ou o par MLKEM_HW+MLKEM_SW, não os dois modos ao mesmo tempo"
  fi
  if [ "$hw_was_set" -ne "$sw_was_set" ]; then
    die "modo avançado exige MLKEM_HW e MLKEM_SW juntos"
  fi

  if [ "$hw_was_set" -eq 1 ]; then
    MLKEM_HW_VALUE="$MLKEM_HW"
    MLKEM_SW_VALUE="$MLKEM_SW"
  else
    selected="${MLKEM_ACCEL:-none}"
    MLKEM_HW_VALUE="$selected"
    MLKEM_SW_VALUE="$selected"
  fi

  case "$MLKEM_HW_VALUE" in none|montmul|montred|both) ;; *) die "MLKEM_HW inválido: $MLKEM_HW_VALUE" ;; esac
  case "$MLKEM_SW_VALUE" in none|montmul|montred|both) ;; *) die "MLKEM_SW inválido: $MLKEM_SW_VALUE" ;; esac

  if [[ "$VEXII_ARGS" =~ (^|[[:space:]])--with-mont(mul|red)($|[=[:space:]]) ]]; then
    die "não passe --with-montmul/--with-montred em VEXII_ARGS; use MLKEM_ACCEL ou MLKEM_HW"
  fi

  case "$MLKEM_SW_VALUE" in
    montmul) [[ "$MLKEM_HW_VALUE" == montmul || "$MLKEM_HW_VALUE" == both ]] \
      || die "firmware montmul exige hardware montmul ou both" ;;
    montred) [[ "$MLKEM_HW_VALUE" == montred || "$MLKEM_HW_VALUE" == both ]] \
      || die "firmware montred exige hardware montred ou both" ;;
    both) [ "$MLKEM_HW_VALUE" = both ] || die "firmware both exige hardware both" ;;
  esac

  case "$MLKEM_HW_VALUE" in
    none)     MLKEM_HW_VEXII_ARGS="" ;;
    montmul)  MLKEM_HW_VEXII_ARGS="--with-montmul" ;;
    montred)  MLKEM_HW_VEXII_ARGS="--with-montred" ;;
    both)     MLKEM_HW_VEXII_ARGS="--with-montmul --with-montred" ;;
  esac
  VEXII_EFFECTIVE_ARGS="$VEXII_ARGS"
  if [ -n "$MLKEM_HW_VEXII_ARGS" ]; then
    VEXII_EFFECTIVE_ARGS="${VEXII_EFFECTIVE_ARGS:+$VEXII_EFFECTIVE_ARGS }$MLKEM_HW_VEXII_ARGS"
  fi
  BUILD_DIR="${MLKEM_BUILD_DIR:-$LITEX_DIR/build/mlkem_hw_${MLKEM_HW_VALUE}_sw_${MLKEM_SW_VALUE}}"
  [[ "$BUILD_DIR" = /* ]] || BUILD_DIR="$REPO_ROOT/$BUILD_DIR"
}

resolve_accel_config

repo_revision() {
  local path="$1" probe top dirty=""
  probe="$path"
  [ -f "$probe" ] && probe="$(dirname "$probe")"
  top="$(git -C "$probe" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$top" ]; then
    [ -n "$(git -C "$top" status --porcelain 2>/dev/null)" ] && dirty="+dirty"
    printf '%s @ %s%s\n' "$top" "$(git -C "$top" rev-parse --short=12 HEAD)" "$dirty"
  else
    printf 'sem repositório Git detectado para %s\n' "$path"
  fi
}

locate_litex_core() {
  [ -d "$LITEX_DIR" ] || die "LITEX_DIR não existe: $LITEX_DIR"
  CORE_PY="$(find "$LITEX_DIR" -type f -path '*/soc/cores/cpu/vexiiriscv/core.py' -print -quit 2>/dev/null)"
  [ -n "$CORE_PY" ] || die "core.py do VexiiRiscv não encontrado sob $LITEX_DIR"
  LITEX_REPO="$(git -C "$(dirname "$CORE_PY")" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$LITEX_REPO" ] || die "core.py não pertence a um checkout Git: $CORE_PY"
}

litex_patch_state() {
  if git -C "$LITEX_REPO" apply --reverse --check "$LITEX_GENERATOR_PATCH" 2>/dev/null; then
    printf 'aplicado'
  elif git -C "$LITEX_REPO" apply --check "$LITEX_GENERATOR_PATCH" 2>/dev/null; then
    printf 'pronto para aplicar'
  else
    printf 'incompatível'
  fi
}

patch_litex_generator() {
  local revision state backup
  locate_litex_core
  [ -f "$LITEX_GENERATOR_PATCH" ] || die "patch do gerador ausente: $LITEX_GENERATOR_PATCH"
  revision="$(git -C "$LITEX_REPO" rev-parse HEAD)"
  [[ "$revision" == "$LITEX_EXPECTED_REV_PREFIX"* ]] \
    || die "LiteX incompatível: esperado $LITEX_EXPECTED_REV_PREFIX..., encontrado $revision"

  state="$(litex_patch_state)"
  case "$state" in
    aplicado)
      say "Patch do gerador LiteX já aplicado"
      ;;
    "pronto para aplicar")
      backup="$CORE_PY.pre-mlkem-local-generator"
      if [ ! -e "$backup" ]; then
        cp "$CORE_PY" "$backup"
        say "Backup criado: $backup"
      fi
      git -C "$LITEX_REPO" apply "$LITEX_GENERATOR_PATCH"
      say "Patch do gerador LiteX aplicado"
      ;;
    *)
      die "core.py não corresponde ao patch validado; nenhuma alteração foi feita: $CORE_PY"
      ;;
  esac

  python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' "$CORE_PY" \
    || die "core.py ficou sintaticamente inválido"
  [ "$(litex_patch_state)" = aplicado ] || die "não foi possível confirmar o patch do gerador"
  echo "    LiteX: $(repo_revision "$CORE_PY")"
  echo "    gerador local esperado: $(repo_revision "$REPO_ROOT")"
  echo "    rollback: git -C $LITEX_REPO apply --reverse $LITEX_GENERATOR_PATCH"
}

if [ "$ACTION" = "--patch-litex" ]; then
  patch_litex_generator
  exit 0
fi

preflight() {
  local patch_state generator_patch_state legacy_line
  local python_version meson_version ninja_version revision

  [ -f "$MLKEM_NATIVE_ROOT/mlkem/mlkem_native.c" ] \
    || die "submódulo mlkem-native ausente; rode: git submodule update --init external/mlkem-native"
  [ -f "$MLKEM_PATCH" ] || die "patch ML-KEM ausente: $MLKEM_PATCH"
  [ -f "$PKG_DIR/bios/mlkem_accel_select.h" ] || die "header de seleção ausente"

  command -v meson >/dev/null 2>&1 || die "Meson ausente no ambiente ativo"
  command -v ninja >/dev/null 2>&1 || die "Ninja ausente no ambiente ativo"
  command -v sbt >/dev/null 2>&1 || die "sbt ausente; necessário para gerar o VexiiRiscv local"
  (cd / && python3 -c 'import litex, litex_boards') >/dev/null 2>&1 \
    || die "python3 não importa litex e litex_boards; ative o ambiente LiteX correto"

  locate_litex_core
  BIOS_DIR="$(find "$LITEX_DIR" -type f -path '*/soc/software/bios/main.c' -printf '%h\n' -quit 2>/dev/null)"
  [ -n "$BIOS_DIR" ] || die "BIOS do LiteX não encontrado sob $LITEX_DIR"

  revision="$(git -C "$LITEX_REPO" rev-parse HEAD)"
  [[ "$revision" == "$LITEX_EXPECTED_REV_PREFIX"* ]] \
    || die "LiteX incompatível: esperado $LITEX_EXPECTED_REV_PREFIX..., encontrado $revision"
  generator_patch_state="$(litex_patch_state)"
  [ "$generator_patch_state" = aplicado ] \
    || die "patch do gerador local está '$generator_patch_state'; rode deploy.sh --patch-litex"
  grep -q 'MLKEM local VexiiRiscv generator' "$CORE_PY" \
    || die "core.py não contém o marcador do gerador local"

  legacy_line="$(grep -En -m1 '^[[:space:]]*[^#].*--with-(mul|div)' "$CORE_PY" || true)"
  if [ -n "$legacy_line" ]; then
    die "core.py ainda injeta flag legada: $CORE_PY ($legacy_line; aplique o Patch 1 documentado no README)"
  fi

  BOARD_TARGET="$(cd / && python3 -c 'import inspect, litex_boards.targets.sipeed_tang_primer_20k as m; print(inspect.getsourcefile(m))' 2>/dev/null || true)"
  [ -n "$BOARD_TARGET" ] && [ -f "$BOARD_TARGET" ] \
    || die "target sipeed_tang_primer_20k não foi localizado no ambiente Python ativo"
  if grep -Eq '^[[:space:]]*self\.specials \+= AsyncResetSynchronizer\(self\.cd_sys, ~pll\.locked \| self\.rst \| self\.reset\)' "$BOARD_TARGET"; then
    die "target ainda contém o segundo driver de sys_rst: $BOARD_TARGET (aplique o Patch 3 documentado no README)"
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

  say "Preflight concluído"
  echo "    BIOS: $BIOS_DIR"
  echo "    Vexii core.py: $CORE_PY"
  echo "    target da placa: $BOARD_TARGET"
  echo "    patch gerador local: $generator_patch_state"
  echo "    gerador Vexii: $(repo_revision "$REPO_ROOT")"
  echo "    patch mlkem-native: $patch_state"
  echo "    aceleração: hw=$MLKEM_HW_VALUE sw=$MLKEM_SW_VALUE"
  echo "    Vexii args efetivos: ${VEXII_EFFECTIVE_ARGS:-<vazio>}"
  echo "    build: $BUILD_DIR"
  echo "    ferramentas: Python $python_version, Meson $meson_version, Ninja $ninja_version"
  echo "    LiteX: $(repo_revision "$CORE_PY")"
  echo "    LiteX-Boards: $(repo_revision "$BOARD_TARGET")"
}

if [ ! -f "$MLKEM_NATIVE_ROOT/mlkem/mlkem_native.c" ] && [ "$ACTION" != "--check" ]; then
  say "Inicializando external/mlkem-native"
  git -C "$REPO_ROOT" submodule update --init external/mlkem-native
fi

preflight
[ "$ACTION" = "--check" ] && exit 0

say "Aplicando o patch versionado do mlkem-native"
make -C "$MLKEM_DIR" prep

say "Copiando arquivos ML-KEM para o BIOS: $BIOS_DIR"
cp "$PKG_DIR/bios/mlkem_litex.c"               "$BIOS_DIR/"
cp "$PKG_DIR/bios/mlkem_native_litex_config.h" "$BIOS_DIR/"
cp "$PKG_DIR/bios/kat_vectors.h"               "$BIOS_DIR/"

write_accel_header() {
  local destination="$BIOS_DIR/mlkem_accel_select.h" temporary
  temporary="$(mktemp)"
  {
    printf '%s\n' '#ifndef MLKEM_ACCEL_SELECT_H' '#define MLKEM_ACCEL_SELECT_H' ''
    printf '#define MLKEM_HW_ACCEL_NAME "%s"\n' "$MLKEM_HW_VALUE"
    printf '#define MLKEM_SW_ACCEL_NAME "%s"\n' "$MLKEM_SW_VALUE"
    case "$MLKEM_HW_VALUE" in
      montmul) printf '%s\n' '#define MLK_HW_HAS_MONTMUL' ;;
      montred) printf '%s\n' '#define MLK_HW_HAS_MONTRED' ;;
      both) printf '%s\n' '#define MLK_HW_HAS_MONTMUL' '#define MLK_HW_HAS_MONTRED' ;;
    esac
    case "$MLKEM_SW_VALUE" in
      montmul) printf '%s\n' '#define MLK_USE_MONTMUL' ;;
      montred) printf '%s\n' '#define MLK_USE_MONTRED' ;;
      both) printf '%s\n' '#define MLK_USE_MONTMUL' '#define MLK_USE_MONTRED' ;;
    esac
    printf '%s\n' '' \
      '#if defined(MLK_USE_MONTMUL) && !defined(MLK_HW_HAS_MONTMUL)' \
      '#error "MLK_USE_MONTMUL requires a VexiiRiscv core with MontMulPlugin"' \
      '#endif' '' \
      '#if defined(MLK_USE_MONTRED) && !defined(MLK_HW_HAS_MONTRED)' \
      '#error "MLK_USE_MONTRED requires a VexiiRiscv core with MontRedPlugin"' \
      '#endif' '' '#endif'
  } > "$temporary"
  if [ -f "$destination" ] && cmp -s "$temporary" "$destination"; then
    rm -f "$temporary"
  else
    mv "$temporary" "$destination"
  fi
}

write_accel_header

# Integração idempotente do mlkem-native no Makefile externo do BIOS.
MK="$BIOS_DIR/Makefile"
[ -f "$MK" ] || die "Makefile do BIOS não encontrado: $MK"
if ! grep -q 'MLKEM_NATIVE_DIR' "$MK"; then
  say "Aplicando integração no Makefile do BIOS (backup em Makefile.pre-mlkem)"
  cp "$MK" "$MK.pre-mlkem"
  MLKEM_NATIVE_DIR="$REPO_ROOT/external/mlkem-native/mlkem"
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
  sed -i 's/^\([[:space:]]*\)crt0\.o/\1mlkem_litex.o \\\n\1mlkem_native.o \\\n\1crt0.o/' "$MK"
  grep -q 'mlkem_litex.o' "$MK" || die "falha ao inserir objetos ML-KEM no Makefile"
else
  say "Makefile do BIOS já contém a integração ML-KEM"
fi
sed -i "s|^MLKEM_NATIVE_DIR ?=.*|MLKEM_NATIVE_DIR ?= $REPO_ROOT/external/mlkem-native/mlkem|" "$MK"

MAIN="$BIOS_DIR/main.c"
if ! grep -q 'litex_mlkem_kat_status' "$MAIN"; then
  say "Aplicando chamada ML-KEM no main.c (backup em main.c.pre-mlkem)"
  cp "$MAIN" "$MAIN.pre-mlkem"
  sed -i '0,/#include "/{s//int litex_mlkem_kat_status(void);\n#include "/}' "$MAIN"
  sed -i 's/\([[:space:]]*\)uart_init();/\1uart_init();\n\t(void)litex_mlkem_kat_status();/' "$MAIN"
  grep -q 'litex_mlkem_kat_status' "$MAIN" || die "falha ao inserir a chamada no main.c"
else
  say "main.c do BIOS já chama o ML-KEM"
fi

[ "$ACTION" = "--install" ] && { say "Instalação concluída (sem build)."; exit 0; }

write_manifest() {
  local status="$1" manifest="$BUILD_DIR/mlkem_build_manifest.md"
  local bitstream="" bitstream_hash="não disponível" reports=""
  mkdir -p "$BUILD_DIR"
  bitstream="$(find "$BUILD_DIR" -type f -name '*.fs' -print -quit 2>/dev/null || true)"
  if [ -n "$bitstream" ] && command -v sha256sum >/dev/null 2>&1; then
    bitstream_hash="$(sha256sum "$bitstream" | awk '{print $1}')"
  fi
  reports="$(find "$BUILD_DIR" -type f \( -name '*.rpt' -o -name '*.html' -o -name '*timing*' \) -print 2>/dev/null | sort || true)"
  {
    printf '# Manifesto do build ML-KEM Montgomery\n\n'
    printf -- '- Data: `%s`\n' "$(date --iso-8601=seconds)"
    printf -- '- Status: `%s`\n' "$status"
    printf -- '- Repositório/gerador: `%s`\n' "$(git -C "$REPO_ROOT" rev-parse HEAD)"
    printf -- '- mlkem-native: `%s`\n' "$(git -C "$MLKEM_NATIVE_ROOT" rev-parse HEAD)"
    printf -- '- LiteX: `%s`\n' "$(git -C "$LITEX_REPO" rev-parse HEAD)"
    printf -- '- LiteX-Boards: `%s`\n' "$(git -C "$(dirname "$BOARD_TARGET")" rev-parse HEAD)"
    printf -- '- Hardware: `%s`\n' "$MLKEM_HW_VALUE"
    printf -- '- Firmware: `%s`\n' "$MLKEM_SW_VALUE"
    printf -- '- CPU variant: `%s`\n' "$CPU_VARIANT"
    printf -- '- Vexii args: `%s`\n' "${VEXII_EFFECTIVE_ARGS:-<vazio>}"
    printf -- '- Clock alvo: `48000000 Hz`\n'
    printf -- '- Python: `%s`\n' "$(python3 -c 'import platform; print(platform.python_version())')"
    printf -- '- Meson: `%s`\n' "$(meson --version)"
    printf -- '- Ninja: `%s`\n' "$(ninja --version)"
    printf -- '- Gowin: `%s`\n' "${GOWIN_HOME:-não informado}"
    printf -- '- Bitstream: `%s`\n' "${bitstream:-não disponível}"
    printf -- '- SHA-256 do bitstream: `%s`\n' "$bitstream_hash"
    printf '\n## Relatórios detectados\n\n```text\n%s\n```\n' "${reports:-nenhum}"
  } > "$manifest"
}

BUILD_FLAGS=(--build)
[ "$ACTION" = "--all" ] && BUILD_FLAGS+=(--load)
VEXII_FLAGS=()
[ -n "$VEXII_EFFECTIVE_ARGS" ] && VEXII_FLAGS+=(--vexii-args="$VEXII_EFFECTIVE_ARGS")

say "Gerando SoC: hw=$MLKEM_HW_VALUE sw=$MLKEM_SW_VALUE"
echo "    gerador: $REPO_ROOT"
echo "    saída: $BUILD_DIR"
export MLKEM_REPO_DIR="$REPO_ROOT"
mkdir -p "$BUILD_DIR"
write_manifest "iniciado"

cd "$LITEX_DIR"
if python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv \
  --cpu-variant="$CPU_VARIANT" \
  --update-repo=no \
  --no-netlist-cache \
  "${VEXII_FLAGS[@]}" \
  --uart-name=serial \
  --bios-console=disable \
  --bios-lto \
  --integrated-rom-size=0x8000 \
  --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  --output-dir="$BUILD_DIR" \
  "${BUILD_FLAGS[@]}"; then
  write_manifest "sucesso"
else
  result=$?
  write_manifest "falha (código $result)"
  exit "$result"
fi

say "Pronto. Para ler a UART"
echo "    python3 -m serial.tools.miniterm $UART_DEV 115200 --raw"
echo "    manifesto: $BUILD_DIR/mlkem_build_manifest.md"
