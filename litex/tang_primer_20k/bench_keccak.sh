#!/usr/bin/env bash
# Um comando: dependências -> build limitado -> SRAM -> UART -> resultados.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$REPO_ROOT/litex/tang_primer_20k"
KECCAK="${KECCAK:-sliced8}"
LITEX_DIR="${LITEX_DIR:-$HOME/litex}"
LITEX_ENV="${LITEX_ENV:-$HOME/litex-env}"
GOWIN_HOME="${GOWIN_HOME:-/var/local/Gowin_V1.9.10.03_Education_linux/IDE}"
SKIP_BUILD=0 CHECK=0 PLAN=0 MONT=0 BARRETT=0 HASH=0 EXPLICIT=0
usage() {
  cat <<EOF
Uso: $0 [perfil] [opções]
  -montgomery                 Montgomery multiply + reduction
  -montgomery_barrett         Montgomery + Barrett (alias: -montgomery_barret)
  -barrett                    Somente Barrett
  -keccak                     Somente Keccak; combine com -montgomery
  -all                        Montgomery + Barrett + Keccak
  Sem perfil: comparação legada C / Montgomery / Montgomery+Keccak (15 KATs).
  Com perfil: C / perfil escolhido, 5 KATs cada, no mesmo boot (10 KATs).
  --arch full|compact|sliced8|sliced16   Keccak (padrão: sliced8)
  --skip-build                Reutiliza imagem com fontes e perfil conferidos
  --check                     Verifica ambiente, sem build ou sincronização Git
  --plan                      Mostra configuração, sem acessar ferramentas/placa
  -h, --help                  Esta ajuda
Resultados: litex/tang_primer_20k/resultados/<data>_<perfil>_<arquitetura>/
EOF
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    -montgomery|--montgomery) MONT=1; EXPLICIT=1 ;;
    -montgomery_barret|-montgomery_barrett|--montgomery-barrett) MONT=1; BARRETT=1; EXPLICIT=1 ;;
    -barrett|--barrett) BARRETT=1; EXPLICIT=1 ;;
    -keccak|--keccak) HASH=1; EXPLICIT=1 ;;
    -all|--all) MONT=1; BARRETT=1; HASH=1; EXPLICIT=1 ;;
    --arch) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; KECCAK="$2"; shift ;;
    --skip-build) SKIP_BUILD=1 ;;
    --check) CHECK=1 ;;
    --plan) PLAN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
case "$KECCAK" in full|compact|sliced8|sliced16) ;; *) echo 'Arquitetura Keccak inválida' >&2; exit 2 ;; esac
SELECTED="$EXPLICIT"
if [ "$EXPLICIT" = 0 ]; then PROFILE=all; HASH=1
else
  case "$MONT$BARRETT$HASH" in
    100) PROFILE=both ;; 110) PROFILE=montgomery-barrett ;; 001) PROFILE=keccak ;;
    101) PROFILE=all ;; 111) PROFILE=all-barrett ;; 010) PROFILE=barrett ;;
    *) echo 'Combinação não suportada; use -all para Barrett + Keccak.' >&2; exit 2 ;;
  esac
fi
LITEX_DIR="${LITEX_DIR/#\~/$HOME}"
LITEX_ENV="${LITEX_ENV/#\~/$HOME}"
GOWIN_HOME="${GOWIN_HOME/#\~/$HOME}"
BUILD_DIR="$LITEX_DIR/build/mlkem_hw_${PROFILE}_sw_${PROFILE}"
[ "$HASH" = 1 ] && [ "$KECCAK" != full ] && BUILD_DIR+="_keccak_$KECCAK"
BUILD_DIR+="_runtime"
[ "$SELECTED" = 1 ] && BUILD_DIR+="_selected"
[[ "$BUILD_DIR" = /* ]] || BUILD_DIR="$REPO_ROOT/$BUILD_DIR"
if [ "$PLAN" = 1 ]; then
  printf 'hw=%s sw=%s selected=%s keccak=%s\nbuild=%s\nKATs=%s\n' "$PROFILE" "$PROFILE" "$SELECTED" "$KECCAK" "$BUILD_DIR" "$(( (3-SELECTED)*5 ))"
  exit 0
fi
cd "$REPO_ROOT"
OUT="$(mktemp -d "$PKG_DIR/resultados/$(date +%Y%m%d_%H%M%S)_${PROFILE}_${KECCAK}_XXXXXX")"
# resultados/ is versioned with a .gitkeep; every attempted run keeps its failure log.
exec > >(tee "$OUT/execucao.log") 2>&1
STAGE=preflight
finish() {
  local rc=$?
  trap - EXIT
  python3 "$PKG_DIR/bench_keccak.py" --finalize "$OUT" --exit-code "$rc" --stage "$STAGE" --build-dir "$BUILD_DIR" || true
  echo "==> Resultados/diagnóstico: $OUT"
  exit "$rc"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
exec 9>"$PKG_DIR/.bench.lock"
flock -n 9 || { echo 'Outro benchmark deste checkout já está ativo.'; exit 1; }
if [ "${VIRTUAL_ENV:-}" != "$LITEX_ENV" ] && [ -f "$LITEX_ENV/bin/activate" ]; then
  source "$LITEX_ENV/bin/activate"
fi
# Prefer the active JDK when compatible, then installed JDKs. Never install packages.
java_ok() {
  local version
  version="$("$1" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -1)"
  [ "${version:-0}" -ge 17 ]
}
JAVA_BIN="$(command -v java || true)"
if [ -n "${JAVA_HOME:-}" ] && java_ok "$JAVA_HOME/bin/java"; then JAVA_BIN="$JAVA_HOME/bin/java"; fi
if [ -z "$JAVA_BIN" ] || ! java_ok "$JAVA_BIN"; then
  JAVA_BIN=""
  for candidate in /usr/lib/jvm/*/bin/java "$HOME"/.sdkman/candidates/java/current/bin/java; do
    if [ -x "$candidate" ] && java_ok "$candidate"; then JAVA_BIN="$candidate"; break; fi
  done
fi
if [ -z "$JAVA_BIN" ]; then
  echo 'ERRO: necessário JDK 17+. No Ubuntu: sudo apt install openjdk-17-jdk'; exit 1
fi
export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$JAVA_BIN")")")"
export JAVACMD="$JAVA_HOME/bin/java"
export PATH="$JAVA_HOME/bin:$GOWIN_HOME/bin:$PATH"
java -version
export SPINALHDL_FROM_SOURCE=1 SPINALHDL_PATH="$REPO_ROOT/ext/SpinalHDL"
DEP_ARGS=()
[ "$CHECK" = 1 ] && DEP_ARGS=(--check)
python3 "$PKG_DIR/bench_support.py" preflight "${DEP_ARGS[@]}"
export PYTHONPATH="$LITEX_DIR/litex:$LITEX_DIR/litex-boards${PYTHONPATH:+:$PYTHONPATH}"
export GOWIN_HOME LITEX_DIR MLKEM_HW="$PROFILE" MLKEM_SW="$PROFILE" MLKEM_RUNTIME_BENCH=1 MLKEM_RUNTIME_SELECTED="$SELECTED" MLKEM_KECCAK_ARCH="$KECCAK"
unset MLKEM_ACCEL MLKEM_BUILD_DIR
[ ! -f /lib/x86_64-linux-gnu/libfreetype.so.6 ] || export LD_PRELOAD="${LD_PRELOAD:-/lib/x86_64-linux-gnu/libfreetype.so.6}"
for tool in python3 sbt timeout openFPGALoader; do command -v "$tool" >/dev/null || { echo "Ferramenta ausente: $tool"; exit 1; }; done
[ "$SKIP_BUILD" = 1 ] || command -v gw_sh >/dev/null || { echo "gw_sh ausente; confira GOWIN_HOME=$GOWIN_HOME"; exit 1; }
python3 -c 'import serial, litex, litex_boards'
UART_ARGS=()
[ -z "${UART_DEV:-}" ] || UART_ARGS=(--uart "$UART_DEV")
UART_DEV="$(python3 "$PKG_DIR/bench_keccak.py" --detect-uart --output "$OUT" "${UART_ARGS[@]}")"
export UART_DEV
echo "==> UART selecionada: $UART_DEV"
if [ "$CHECK" = 1 ]; then "$PKG_DIR/deploy.sh" --check; STAGE=checagem; exit 0; fi
IDENTITY_ARGS=(--build-dir "$BUILD_DIR" --profile "$PROFILE" --architecture "$KECCAK" --selected "$SELECTED")
if [ "$SKIP_BUILD" = 0 ]; then
  STAGE=build
  # Single build attempt, bounded at 20 minutes including a 10s termination grace.
  # Install first: the snapshot includes the effective patched BIOS/Makefile/core.
  timeout --kill-after=10s 1190s bash -e -c '
    "$1/deploy.sh" --patch-litex
    "$1/deploy.sh" --install
    python3 "$1/bench_support.py" begin --build-dir "$2" --profile "$3" --architecture "$4" --selected "$5"
    "$1/deploy.sh" --build
  ' _ "$PKG_DIR" "$BUILD_DIR" "$PROFILE" "$KECCAK" "$SELECTED" 2>&1 | tee "$OUT/build.log"
  python3 "$PKG_DIR/bench_support.py" stamp "${IDENTITY_ARGS[@]}"
fi
BITSTREAM="$(python3 "$PKG_DIR/bench_support.py" verify "${IDENTITY_ARGS[@]}")"
cp "$BUILD_DIR/bench_identity.json" "$OUT/bench_identity.json"
STAGE=uart
ARGS=()
[ -z "${OFL_FTDI_SERIAL:-}" ] || ARGS+=(--loader-arg=--ftdi-serial --loader-arg="$OFL_FTDI_SERIAL")
[ -z "${UART_DEV:-}" ] || ARGS+=(--uart "$UART_DEV")
[ "$SELECTED" = 0 ] || ARGS+=(--profile "$PROFILE")
python3 "$PKG_DIR/bench_keccak.py" --build-dir "$BUILD_DIR" --bitstream "$BITSTREAM" --output "$OUT" --existing-output \
  --label "commit=$(git rev-parse --short=12 HEAD) keccak=$KECCAK hw=$PROFILE sw=$PROFILE selected=$SELECTED" "${ARGS[@]}"
STAGE=concluido
