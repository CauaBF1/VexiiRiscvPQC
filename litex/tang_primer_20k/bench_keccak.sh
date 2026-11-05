#!/usr/bin/env bash
# Benchmark completo na Tang Primer 20K a partir do checkout atual (git pull e pronto):
#   build (hw=all, firmware runtime C / Montgomery / Montgomery+Keccak)
#   -> grava a SRAM -> captura a UART -> salva CSV/JSON/RESUMO em litex/tang_primer_20k/resultados/.
#
# Uso no vlab:
#   ./litex/tang_primer_20k/bench_keccak.sh               # arquitetura Keccak sliced8
#   KECCAK=full ./litex/tang_primer_20k/bench_keccak.sh   # full | compact | sliced8 | sliced16
#   ./litex/tang_primer_20k/bench_keccak.sh --skip-build  # regrava/mede o último build
#
# Ambiente: usa ~/litex-env, ~/litex e o Gowin do vlab por padrão; tudo pode ser
# sobrescrito por variável (LITEX_ENV, LITEX_DIR, GOWIN_HOME, UART_DEV, OFL_FTDI_SERIAL).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$REPO_ROOT/litex/tang_primer_20k"
KECCAK="${KECCAK:-sliced8}"
LITEX_DIR="${LITEX_DIR:-$HOME/litex}"
LITEX_ENV="${LITEX_ENV:-$HOME/litex-env}"
GOWIN_HOME="${GOWIN_HOME:-/var/local/Gowin_V1.9.10.03_Education_linux/IDE}"
LITEX_DIR="${LITEX_DIR/#\~/$HOME}"
LITEX_ENV="${LITEX_ENV/#\~/$HOME}"
GOWIN_HOME="${GOWIN_HOME/#\~/$HOME}"
SKIP_BUILD=0
case "${1:-}" in
  "") ;;
  --skip-build) SKIP_BUILD=1 ;;
  *) echo "uso: $0 [--skip-build]" >&2; exit 1 ;;
esac

# Ambiente LiteX/Gowin (idempotente; não altera nada fora desta sessão).
if [ -z "${VIRTUAL_ENV:-}" ] && [ -f "$LITEX_ENV/bin/activate" ]; then
  # shellcheck disable=SC1091
  source "$LITEX_ENV/bin/activate"
fi
export PYTHONPATH="${PYTHONPATH:-$LITEX_DIR/litex:$LITEX_DIR/litex-boards}"
export GOWIN_HOME
export PATH="$GOWIN_HOME/bin:$PATH"
[ -f /lib/x86_64-linux-gnu/libfreetype.so.6 ] && export LD_PRELOAD="${LD_PRELOAD:-/lib/x86_64-linux-gnu/libfreetype.so.6}"

export LITEX_DIR MLKEM_HW=all MLKEM_SW=all MLKEM_RUNTIME_BENCH=1 MLKEM_KECCAK_ARCH="$KECCAK"
unset MLKEM_ACCEL MLKEM_BUILD_DIR
BUILD_DIR="$LITEX_DIR/build/mlkem_hw_all_sw_all"
[ "$KECCAK" != full ] && BUILD_DIR+="_keccak_$KECCAK"
BUILD_DIR+="_runtime"
[[ "$BUILD_DIR" = /* ]] || BUILD_DIR="$REPO_ROOT/$BUILD_DIR"

cd "$REPO_ROOT"
git submodule update --init external/mlkem-native
COMMIT="$(git rev-parse --short=12 HEAD)"
[ -n "$(git status --porcelain --ignore-submodules=all)" ] && COMMIT+="+dirty"
OUT="$PKG_DIR/resultados/$(date +%Y%m%d_%H%M%S)_keccak_${KECCAK}"

if [ "$SKIP_BUILD" = 0 ]; then
  mkdir -p "$LITEX_DIR/build"
  "$PKG_DIR/deploy.sh" --patch-litex
  "$PKG_DIR/deploy.sh" --build 2>&1 | tee "$BUILD_DIR.build.log"
fi
mkdir -p "$(dirname "$OUT")"

LOADER_ARGS=()
[ -n "${OFL_FTDI_SERIAL:-}" ] && LOADER_ARGS=(--loader-arg=--ftdi-serial --loader-arg="$OFL_FTDI_SERIAL")
UART_ARGS=()
[ -n "${UART_DEV:-}" ] && UART_ARGS=(--uart "$UART_DEV")

status=0
python3 "$PKG_DIR/bench_keccak.py" --build-dir "$BUILD_DIR" --output "$OUT" \
  --label "commit=$COMMIT keccak=$KECCAK hw=all sw=all runtime=1" \
  "${UART_ARGS[@]}" "${LOADER_ARGS[@]}" || status=$?
[ -d "$OUT" ] && [ -f "$BUILD_DIR.build.log" ] && gzip -c "$BUILD_DIR.build.log" > "$OUT/build.log.gz"

cat <<EOF

==> Para enviar os resultados ao GitHub:
    git add litex/tang_primer_20k/resultados && git commit -m "bench: keccak $KECCAK $(basename "$OUT")" && git push
EOF
exit "$status"
