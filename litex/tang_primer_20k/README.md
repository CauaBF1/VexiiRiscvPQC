# ML-KEM-512 no LiteX + VexiiRiscv — Sipeed Tang Primer 20K

Integração para rodar o ML-KEM-512 na **Sipeed Tang Primer 20K** com a CPU
**VexiiRiscv**, gerada pelo LiteX. O ML-KEM roda como app do **BIOS do LiteX**:
no boot executa keypair/encaps/decaps, valida o KAT byte-a-byte e imprime pela
UART, medindo ciclos com o `timer0` do LiteX.

```text
[MLKEM] ML-KEM-512 KAT start
[MLKEM] bench_keypair_cycles=...
[MLKEM] bench_encaps_cycles=...
[MLKEM] bench_decaps_cycles=...
[MLKEM] KAT PASS
```

Os arquivos do BIOS (`bios/mlkem_litex.c`, `bios/mlkem_native_litex_config.h`,
`bios/kat_vectors.h`) são **agnósticos de CPU** — usam só APIs do LiteX
(`csr.h`, `timer0`, `printf`) e as APIs *derand* do `mlkem-native`. São os mesmos
da integração de referência (VexRiscv 32-bit); o que muda é o SoC gerado com
`--cpu-type=vexiiriscv`.

## Fluxo "git pull + 1 comando" (no PC da placa)

No computador onde a Tang está conectada, com o LiteX já clonado (ex.: `~/litex`):

```bash
cd ~/VexiiRiscvPQC        # este repo
git pull
LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh
```

O `deploy.sh` faz tudo, de forma **idempotente** (pode rodar de novo sem quebrar):

1. `git submodule update --init external/mlkem-native` (git pull **não** atualiza submódulos);
2. localiza o BIOS do LiteX sob `LITEX_DIR`;
3. copia os arquivos ML-KEM para o BIOS;
4. faz *patch* no `Makefile` do BIOS (injeta o caminho do `mlkem-native` **deste**
   repo e adiciona os objetos) e no `main.c` (chama o ML-KEM no boot) — com backup
   `*.pre-mlkem`;
5. gera o SoC VexiiRiscv e grava na placa
   (`--cpu-type=vexiiriscv --build --load`).

Ler a UART (outro terminal):
```bash
python3 -m litex.tools.litex_term /dev/ttyUSB1 --speed 115200
# se corromper: python3 -m serial.tools.miniterm /dev/ttyUSB1 115200 --raw
```

### Variáveis (todas com default)
| Var | Default | Para quê |
|---|---|---|
| `LITEX_DIR` | `~/litex` | raiz do LiteX clonado (contém `litex/`, `litex-boards/`, …) |
| `CPU_VARIANT` | `standard` | variant VexiiRiscv no LiteX (`standard`/`cached`/`linux`) |
| `VEXII_ARGS` | `--with-mul --with-div` | flags do gerador do core (ex.: `--with-rvZbb --with-rvZba`) |
| `UART_DEV` | `/dev/ttyUSB1` | porta serial |

### Modos
```bash
./litex/tang_primer_20k/deploy.sh --install   # só instala no BIOS (sem build)
./litex/tang_primer_20k/deploy.sh --build     # instala + build (sem gravar)
./litex/tang_primer_20k/deploy.sh --all       # instala + build + load (default)
```

## O que o `git pull` cobre e o que NÃO cobre

**Coberto pelo git pull** (versionado neste repo): os arquivos do BIOS, o
`deploy.sh` e (via `submodule update`, feito pelo script) o `external/mlkem-native`.

**NÃO coberto — precisa existir uma vez no PC da placa** (ambiente, não git):
- LiteX clonado/instalado (você já tem em `~/`) — `litex_setup.py`;
- toolchain RISC-V bare-metal usada pelo LiteX;
- Gowin EDA (`gw_sh`) e `openFPGALoader`/loader Gowin;
- acesso à placa (JTAG/FTDI) e à UART;
- este repositório VexiiRiscv clonado (para o LiteX gerar o core via
  `sbt runMain vexiiriscv.soc.litex.SocGen`) + `sbt`/Java.

Ambiente Gowin típico (exporte antes de rodar, conforme sua instalação):
```bash
export GOWIN_HOME=/opt/Gowin/IDE
export PATH=$GOWIN_HOME/bin:$PATH
export LD_PRELOAD=/lib/x86_64-linux-gnu/libfreetype.so.6
```

## Aceleração (opcional)

Para experimentar extensões escalares no core (ver
`understanding/plano_aceleracao.md`), passe pelo `VEXII_ARGS` **e** garanta que
o `-march` do BIOS inclua a mesma extensão (core e firmware sempre com a mesma
ISA):
```bash
VEXII_ARGS="--with-mul --with-div --with-rvZbb --with-rvZba" \
  LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh
```

## Status

- Os arquivos do BIOS são reaproveitados da integração **validada** em FPGA da
  referência (VexRiscv 32-bit), que produziu `KAT PASS` na Tang Primer 20K.
- O *patcher* do `deploy.sh` foi testado em sandbox (Makefile/main.c de exemplo).
- O fluxo completo **com VexiiRiscv** ainda **não foi executado em hardware**
  neste ambiente (sem placa/LiteX/Gowin aqui). Confira `CPU_VARIANT` e o
  `-march`/`-mabi` do BIOS conforme o core que o LiteX gerar antes de gravar.
```
