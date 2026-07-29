#!/usr/bin/env bash
# Deploy do ML-KEM-512 no BIOS do LiteX + build/load para Sipeed Tang Primer 20K
# com CPU VexiiRiscv. Pensado para rodar no computador onde a placa está conectada,
# logo após um `git pull` deste repositório.
#
# Uso:
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh            # instala + build + load
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --install  # só instala no BIOS
#   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --build    # instala + build (sem gravar)
#
# Variáveis (todas com default):
#   LITEX_DIR      raiz do LiteX já clonado (contém litex/, litex-boards/, ...). default: ~/litex
#   CPU_VARIANT    variant do VexiiRiscv no LiteX. default: standard
#   VEXII_ARGS     flags extras para o gerador do core. default: "--with-mul --with-div"
#   UART_DEV       porta serial para o litex_term. default: /dev/ttyUSB1
set -euo pipefail

ACTION="${1:---all}"                                  # --install | --build | --all
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$REPO_ROOT/litex/tang_primer_20k"
LITEX_DIR="${LITEX_DIR:-$HOME/litex}"
CPU_VARIANT="${CPU_VARIANT:-standard}"
VEXII_ARGS="${VEXII_ARGS:---with-mul --with-div}"
UART_DEV="${UART_DEV:-/dev/ttyUSB1}"

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mERRO: %s\033[0m\n' "$*" >&2; exit 1; }

# --- 1. submódulo do algoritmo (git pull NÃO atualiza submódulos sozinho) ---
say "Garantindo external/mlkem-native"
git -C "$REPO_ROOT" submodule update --init external/mlkem-native
[ -f "$REPO_ROOT/external/mlkem-native/mlkem/mlkem_native.c" ] || die "mlkem-native ausente após submodule update"

# --- 2. localizar o BIOS do LiteX ---
[ -d "$LITEX_DIR" ] || die "LITEX_DIR não existe: $LITEX_DIR (defina LITEX_DIR=/caminho/do/litex)"
BIOS_DIR="$(find "$LITEX_DIR" -type f -path '*/soc/software/bios/main.c' -printf '%h\n' 2>/dev/null | head -1)"
[ -n "$BIOS_DIR" ] || die "BIOS do LiteX não encontrado sob $LITEX_DIR (esperado .../soc/software/bios/main.c)"
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
BUILD_FLAGS="--build"
[ "$ACTION" = "--all" ] && BUILD_FLAGS="--build --load"
say "Gerando SoC VexiiRiscv para Tang Primer 20K ($BUILD_FLAGS)"
echo "    (LiteX chama internamente: sbt runMain vexiiriscv.soc.litex.SocGen ...)"
export MLKEM_REPO_DIR="$REPO_ROOT"
cd "$LITEX_DIR"
python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv \
  --cpu-variant="$CPU_VARIANT" \
  --vexii-args="$VEXII_ARGS" \
  --uart-name=serial \
  --integrated-rom-size=0xc000 \
  --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  $BUILD_FLAGS

say "Pronto. Para ler a UART:"
echo "    python3 -m litex.tools.litex_term $UART_DEV --speed 115200"
echo "    # se corromper:  python3 -m serial.tools.miniterm $UART_DEV 115200 --raw"
