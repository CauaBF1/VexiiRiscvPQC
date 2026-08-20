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

## Aceleração

As alavancas entram por `--vexii-args` do LiteX (mesmo parser `ParamSimple` do
TestBench de sim — confirmado em
`src/main/scala/vexiiriscv/soc/litex/Soc.scala:72,108`). Ganho em ciclos foi medido
em **simulação** (rv64); a placa é **rv32** e só imprime `KAT PASS` + ciclos do
`timer0` — serve para **corretude** e para o dado que a sim não dá: **área/Fmax**
(do relatório de síntese do `--build`).

> ⚠️ **Não passe `--with-mul --with-div`.** O commit pinado do VexII (mudança
> "isamap") **rejeita** essas flags (`Unknown option`); o M já entra pela ISA do
> variant (`isa_map`, o `core.py` do LiteX adiciona `m`). O forwarding
> `--allow-bypass-from=0` **já é default** do `core.py` do LiteX (o Patch 1 do vlab
> o mantém). Detalhes na §3 de `understanding/done_execucao_vexii_vlab.md`.

### Sweet-spot de microarquitetura (recomendado) — só flags, sem tocar no firmware

Diferente do Zbb, essas flags **não mudam a ISA** → **não precisam casar o `-march`
do BIOS**; o mesmo firmware rv32 vale. A campanha de sim
(`understanding/benchmarks/microarch_sweep/`) mostrou que a alavanca dominante é o
**register forwarding** (2.4× sozinho — já default aqui), seguido de branch
prediction. Como o bypass já vem ligado, o que **falta adicionar** é:

```
--vexii-args="--with-btb --with-ras --with-gshare"
```

- `--allow-bypass-from=0` — **forwarding** (resultado direto da ALU à próxima
  instrução, sem esperar o writeback). O maior lever; **já é default** do LiteX.
- `--with-btb --with-ras --with-gshare` — **branch prediction** (destino + direção
  + retorno de função). Custo de área médio (RAMs do BTB/GShare).
- Opcional `--with-late-alu` (2º port de ALU): rendeu só +3% na sim e adiciona
  caminho combinacional → **na placa pode baixar o Fmax**; se o timing falhar,
  `--relaxed-branch`/`--relaxed-btb`.
- Onde colar isso no fluxo real: ver **"Executar no vlab"** abaixo (é onde o
  `--vexii-args` é adicionado ao comando do target).

### Tier caro (avaliar se cabe na 20K) — dual-issue

~3.8× na sim, mas **duplica a lógica de execução** (`--decoders=2 --lanes=2`) e pode
**não caber**/não fechar timing na Tang Primer 20K (Gowin pequeno; o vlab já teve de
reduzir caches para caber na BSRAM). Só tentar depois que o sweet-spot fechar:
```
--vexii-args="--with-btb --with-ras --with-gshare --decoders=2 --lanes=2 --with-aligner-buffer --with-dispatcher-buffer"
```

### ISA — Zbb (precisa casar o `-march` do BIOS)

Ortogonal (corta contagem de instruções, ~1.24×). Como **muda a ISA**, além do
`--vexii-args="--with-rvZbb --with-rvZba"` é preciso que o `-march` do BIOS do LiteX
inclua `_zbb` (core e firmware sempre com a mesma ISA). Combinável com o sweet-spot
(junte as flags). Ver `understanding/plano_aceleracao.md`.

---

## Executar no vlab (passo a passo validado)

Fluxo **realmente executado** (deu `KAT PASS` na Tang Primer 20K), resumido de
`GUIA_EXECUCAO_MLKEM.md` + `understanding/done_execucao_vexii_vlab.md`. Pressupõe a
conta `caua` do vlab já preparada: repo em `~/VexiiRiscvPQC`, LiteX em `~/litex` com
venv `~/litex-env` e os **patches aplicados**, Gowin instalado, placa conectada.

> ⚠️ Na placa o VexII sai **rv32im** (variant `standard` do LiteX é 32-bit). O
> ML-KEM roda e valida igual (KAT PASS). Não há contagem de ciclos comparável à sim
> (xlen e memória diferentes) — o valor aqui é **corretude** + **área/Fmax**.

**0. Entrar e preparar o ambiente** (o Gowin precisa do `LD_PRELOAD` do freetype):
```bash
ssh vlab                     
cd ~/litex
source ~/litex-env/bin/activate
export PYTHONPATH=$PWD/litex:$PWD/litex-boards
export GOWIN_HOME=/var/local/Gowin_V1.9.10.03_Education_linux/IDE
export PATH=$GOWIN_HOME/bin:$PATH
export LD_PRELOAD=/lib/x86_64-linux-gnu/libfreetype.so.6
```

**1. Abrir a UART ANTES de gravar** (terminal A) — o ML-KEM imprime **uma vez no
boot**; o console é o canal B do FT2232 → `/dev/ttyUSB2`:
```bash
source ~/litex-env/bin/activate
python3 -m litex.tools.litex_term /dev/ttyUSB2 --speed 115200
# sem /dev/ttyUSB*?  sudo modprobe -r ftdi_sio && sudo modprobe ftdi_sio  (ou replug do cabo)
```

**2. Reaplicar os patches do LiteX** (só se o `~/litex` for novo — senão pule):
```bash
# Patch 1 — remove --with-mul/--with-div (isamap rejeita), mantém o bypass
sed -i 's/ --with-mul --with-div --allow-bypass-from=0/ --allow-bypass-from=0/' \
  ~/litex/litex/litex/soc/cores/cpu/vexiiriscv/core.py
# Patch 3 — remove 2º driver de sys_rst (GowinSynthesis rejeita multi-driver)
sed -i 's@self.specials += AsyncResetSynchronizer(self.cd_sys, ~pll.locked | self.rst | self.reset)@#&@' \
  ~/litex/litex-boards/litex_boards/targets/sipeed_tang_primer_20k.py
pip3 install meson ninja   # Patch 2 (dependência de build do BIOS)
```

**3. Build + load (terminal B)** — é aqui que o **sweet-spot** entra, via
`--vexii-args` adicionado ao comando validado:
```bash
cd ~/litex
python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv --cpu-variant=standard --uart-name=serial \
  --vexii-args="--with-btb --with-ras --with-gshare" \
  --bios-console=disable --bios-lto \
  --integrated-rom-size=0x8000 --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  --build --load
```
- **Sem sweet-spot** (baseline validado): apagar a linha `--vexii-args=...`.
- **Só medir área/Fmax** (sem placa): trocar `--build --load` por `--build` e ler
  o relatório de síntese Gowin em `build/sipeed_tang_primer_20k/`.
- **Re-gravar** um `.fs` já gerado (rápido, não recompila):
  ```bash
  openFPGALoader --cable ft2232 \
    --bitstream ~/litex/build/sipeed_tang_primer_20k/gateware/sipeed_tang_primer_20k.fs
  ```

**4. Verificar no terminal A:**
```text
[MLKEM] ML-KEM-512 KAT start
[MLKEM] bench_keypair_cycles=...
[MLKEM] KAT PASS
```
`KAT PASS` = pk/sk/ct/ss bateram byte-a-byte com o sweet-spot ativo. O bitstream
vai para SRAM volátil (some ao desligar).

> Alternativa: o `deploy.sh` deste repo automatiza o patch do BIOS e chama o mesmo
> target — mas o fluxo **provado** é o manual acima. Se usar o `deploy.sh`, passe o
> sweet-spot por `VEXII_ARGS="--with-btb --with-ras --with-gshare"` (sem mul/div) e
> garanta que os Patches 1/3 do LiteX estão aplicados.

## Status

- Os arquivos do BIOS são reaproveitados da integração **validada** em FPGA da
  referência (VexRiscv 32-bit), que produziu `KAT PASS` na Tang Primer 20K.
- O *patcher* do `deploy.sh` foi testado em sandbox (Makefile/main.c de exemplo).
- O fluxo completo **com VexiiRiscv** ainda **não foi executado em hardware**
  neste ambiente (sem placa/LiteX/Gowin aqui). Confira `CPU_VARIANT` e o
  `-march`/`-mabi` do BIOS conforme o core que o LiteX gerar antes de gravar.
```
