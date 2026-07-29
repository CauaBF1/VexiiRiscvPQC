# ML-KEM-512 no VexiiRiscv (64-bit)

Guia de execução do ML-KEM-512 (Kyber) neste repositório **VexiiRiscv**. Cobre:

1. execução em **simulação** (benchmark e KAT) — fluxo validado;
2. execução **na placa Sipeed Tang Primer 20K** usando VexiiRiscv **via LiteX**
   — documentado, **sem instalar o LiteX aqui** (o guia mostra como fazer).

O algoritmo vem do submódulo `external/mlkem-native`. O firmware de simulação
está em `src/main/c/vexii/mlkem512/`. Para o contexto do porte
VexRiscv→VexiiRiscv, ver `understanding/implementacao_inicial_vexii.md`.

---

## Dependências

- `git`, `make`, `python3`
- `sbt` + Java (OpenJDK 17+)
- `verilator` (≥ 5.x), `g++`
- Toolchain bare-metal RISC-V 64-bit com newlib, ex.:
  `riscv64-unknown-elf-gcc` com multilib `rv64imac/lp64`.

Conferir o multilib:
```bash
riscv64-unknown-elf-gcc --print-multi-lib   # deve listar rv64imac/lp64
```

O `makefile` do firmware usa por padrão:
```make
RISCV_NAME ?= riscv64-unknown-elf
RISCV_PATH ?= /home/borgescaua/opt/riscv-elf-multilib
MABI  := lp64
MARCH := rv64imac_zicsr
```
Ajuste `RISCV_PATH`/`RISCV_NAME` se sua toolchain estiver em outro lugar.

---

## Preparar o repositório

```bash
git submodule update --init external/mlkem-native      # algoritmo ML-KEM-512
git submodule update --init ext/SpinalHDL ext/rvls      # simulação (SpinalHDL do source + bindings rvls)
```

---

## Executar o benchmark (simulação)

Roda `keypair`, `encapsulation` e `decapsulation`, imprime prefixos de
`pk`/`ct`/`ss1`/`ss2` e mede ciclos com `rdcycle`.

```bash
# 1) compilar o firmware (rv64)
make -B -C src/main/c/vexii/mlkem512 BENCH_ROUNDS=2 all

# 2) rodar na simulação VexiiRiscv
sbt "runMain vexiiriscv.tester.TestBench \
  --load-elf src/main/c/vexii/mlkem512/build/mlkem512.elf \
  --xlen 64 --with-rvm --with-rvc --performance-counters 0 \
  --reset-vector 2147483648 --no-rvls-check"
```

Saída esperada (resumida):
```text
VexiiRiscv ML-KEM-512 start
round=0000000000000001
keypair_ret=0x0  enc_ret=0x0  dec_ret=0x0  ss_match=0x1
pk_prefix=0ED44902DA2DF3F3
ct_prefix=2CD4558045559D6D
ss1_prefix=2ABA253D50DC878B
ss2_prefix=2ABA253D50DC878B
cycles_keypair=0x...  cycles_enc=0x...  cycles_dec=0x...
done
```
`ss_match=0x1` indica que o shared secret encapsulado e o decapsulado bateram.
Para mudar o número de rodadas: `BENCH_ROUNDS=30`.

---

## Executar o KAT (simulação)

Valida `pk`/`sk`/`ct`/`ss` **byte-a-byte** contra vetores de referência
(`src/main/c/vexii/mlkem512/src/kat_vectors.h`), usando coins fixas via
`mlkem_keypair_derand`/`mlkem_enc_derand`.

```bash
# 1) compilar em modo KAT
make -B -C src/main/c/vexii/mlkem512 KAT=yes all

# 2) rodar (exit 0 = KAT PASS)
sbt "runMain vexiiriscv.tester.TestBench \
  --load-elf src/main/c/vexii/mlkem512/build/mlkem512.elf \
  --xlen 64 --with-rvm --with-rvc --performance-counters 0 \
  --reset-vector 2147483648 --no-rvls-check"
```

Saída esperada:
```text
VexiiRiscv ML-KEM-512 KAT start
keypair_ret=0x0  enc_ret=0x0  dec_ret=0x0
pk_match=0x1  sk_match=0x1  ct_match=0x1  ss_match=0x1
kat_pass=0x1
done
```
No VexiiRiscv **não** há runner externo: o `main` retorna 0 só se tudo bate, o
PC atinge o símbolo `pass`, e o **exit code 0 do sbt é o veredito do KAT**.

### Por que os flags do simulador importam
| Flag | Motivo |
|---|---|
| `--xlen 64` | núcleo de 64 bits (default é rv32) |
| `--with-rvm` | extensão M (multiplicação do Kyber) |
| `--with-rvc` | extensão C (casa com o multilib `rv64imac`) |
| `--performance-counters 0` | habilita `zicntr` → CSR `cycle`; sem isso `rdcycle` faz *trap* |
| `--reset-vector 2147483648` | `0x80000000`, onde o `linker.ld` põe a RAM |
| `--no-rvls-check` | roda sem o lockstep rvls (a `.so` nativa não é necessária) |

---

## Comandos úteis

```bash
make -C src/main/c/vexii/mlkem512 clean        # limpar build do firmware
```

---

## Executar na placa pelo vlab (ambiente já preparado) ✅ VALIDADO

Este é o fluxo **realmente executado e validado** (deu `KAT PASS` na Tang Primer
20K). Pressupõe que **tudo já está pronto na conta `caua` do vlab**: o repositório
em `~/VexiiRiscvPQC` (com submódulo), o LiteX em `~/litex` com o venv `~/litex-env`
e os patches aplicados, o Gowin instalado e a placa conectada. Para o *porquê* de
cada patch e da configuração, ver `understanding/done_execucao_vexii_vlab.md`.

> ⚠️ Na placa o VexII sai como **rv32im (32-bit)**, não 64-bit — o variant
> `standard` do LiteX é 32-bit. O ML-KEM roda e valida igual (KAT PASS). A
> discussão sim(64)×placa(32) e a inviabilidade de 64-bit no GW2A-18 estão na §11
> do `done_execucao_vexii_vlab.md`.

### 0. Entrar no vlab e preparar o terminal

```bash
ssh vlab                     # entra como caua
cd ~/litex
source ~/litex-env/bin/activate
export PYTHONPATH=$PWD/litex:$PWD/litex-boards
export GOWIN_HOME=/var/local/Gowin_V1.9.10.03_Education_linux/IDE
export PATH=$GOWIN_HOME/bin:$PATH
export LD_PRELOAD=/lib/x86_64-linux-gnu/libfreetype.so.6
```

### 1. Abrir a UART (terminal A) — **antes** de gravar

O ML-KEM imprime **uma vez no boot**, então abra a serial primeiro. O console é o
canal B do FT2232 → **`/dev/ttyUSB2`**:

```bash
source ~/litex-env/bin/activate
python3 -m litex.tools.litex_term /dev/ttyUSB2 --speed 115200
```

Se **não houver** `/dev/ttyUSB*` (o `openFPGALoader` costuma soltar o `ftdi_sio`):
```bash
sudo modprobe -r ftdi_sio && sudo modprobe ftdi_sio   # recria as portas
# sem sudo: pedir um replug do cabo USB da placa
ls /dev/ttyUSB*                                        # deve listar USB0/USB1/USB2
```

### 2. Gravar o bitstream (terminal B) — dispara o boot e o KAT

O bitstream vai para a **SRAM (volátil)**: some ao desligar. Se o `build/` já
existe, basta **re-gravar** o `.fs` já gerado (rápido, não recompila nada):

```bash
# (mesmas exports da etapa 0 neste terminal)
openFPGALoader --cable ft2232 \
  --bitstream ~/litex/build/sipeed_tang_primer_20k/gateware/sipeed_tang_primer_20k.fs
```

No **terminal A** deve aparecer:
```text
[MLKEM] ML-KEM-512 KAT start
[MLKEM] bench_keypair_cycles=935266
[MLKEM] bench_encaps_cycles=1072913
[MLKEM] bench_decaps_cycles=1356973
[MLKEM] KAT PASS
```
(seguido do banner do BIOS e `No boot medium found` — normal; o ML-KEM roda antes
do boot). `KAT PASS` = pk/sk/ct/ss bateram byte-a-byte.

### 3. (Só se precisar) Regerar o bitstream do zero

Se o `build/` foi apagado ou você mudou algo, rode o build completo (regenera
netlist + BIOS + gateware; leva alguns minutos):

```bash
cd ~/litex
python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv --cpu-variant=standard \
  --uart-name=serial \
  --bios-console=disable --bios-lto \
  --integrated-rom-size=0x8000 --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  --build --load
```

> ⚠️ Se você recriar o `~/litex` do zero (novo clone), os **patches somem** e o
> build falha. Reaplicar antes de buildar (detalhes/porquês no
> `done_execucao_vexii_vlab.md`):
> ```bash
> # Patch 1 — remove flags legadas que o VexII "isamap" rejeita
> sed -i 's/ --with-mul --with-div --allow-bypass-from=0/ --allow-bypass-from=0/' \
>   ~/litex/litex/litex/soc/cores/cpu/vexiiriscv/core.py
> # Patch 3 — remove o 2º driver de sys_rst (GowinSynthesis rejeita multi-driver)
> sed -i 's@self.specials += AsyncResetSynchronizer(self.cd_sys, ~pll.locked | self.rst | self.reset)@#&@' \
>   ~/litex/litex-boards/litex_boards/targets/sipeed_tang_primer_20k.py
> # Patch 2 — dependência de build do BIOS
> pip3 install meson ninja
> # + recopiar os 3 arquivos do bios e reaplicar o patch do Makefile/main.c
> ```

---

## Executar na placa Sipeed Tang Primer 20K com VexiiRiscv (via LiteX)

> ℹ️ A seção abaixo é a documentação **genérica/original** (escrita antes da
> execução real). O fluxo **provado** é o **"Executar na placa pelo vlab"** acima.
> Onde houver divergência (ex.: `--vexii-args`, tamanho de ROM, porta serial),
> vale o fluxo do vlab.

> **Este repositório NÃO instala o LiteX.** Esta seção documenta como fazer o
> fluxo de placa. Os comandos de **simulação** acima são os validados; o fluxo
> de placa abaixo segue a integração de referência
> (`../VexRiscvPQC/litex_sipeed_mlkem_integration`) adaptada para o VexiiRiscv,
> e deve ser conferido no seu ambiente de FPGA.

### Conceito (como o LiteX usa o VexiiRiscv)

O LiteX tem o VexiiRiscv como CPU de primeira classe: `--cpu-type=vexiiriscv`.
Ao gerar o SoC, o LiteX **chama o gerador deste repositório** internamente via:

```text
sbt "runMain vexiiriscv.soc.litex.SocGen <args>"
```

produzindo o Verilog do core. Flags específicas do VexiiRiscv (mesma família das
que passamos ao `TestBench`) são repassadas com **`--vexii-args="..."`**.

- Variants aceitos pelo wrapper LiteX: `standard`, `cached`, `linux`, `debian`.
- march/mabi default: `rv{xlen}i…` + subconjunto `mafdc`; ABI `lp64`/`ilp32`.

**Importante — dois "firmwares" diferentes:**
O ELF de simulação em `src/main/c/vexii/mlkem512/` fala com o
`PeripheralEmulator` do testbench (`PUTC` em `0x10000000`, símbolos
`pass`/`fail`). **Ele não roda na placa.** Na placa, o ML-KEM roda como **app do
BIOS do LiteX**, usando a UART e o `timer0` do LiteX — exatamente a abordagem da
pasta de integração de referência, que é **C agnóstico de CPU** (usa as APIs do
LiteX, não MMIO do core), então funciona igual sob VexiiRiscv.

### Passo 1 — Instalar o LiteX (uma vez, fora deste repo)

Fonte oficial: `enjoy-digital/litex` (script `litex_setup.py`).
```bash
mkdir -p ~/litex && cd ~/litex
wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
chmod +x litex_setup.py
./litex_setup.py --init --install --user       # baixa litex, litex-boards, migen, etc.
```
Também são necessários:
- toolchain RISC-V (a mesma bare-metal serve para o BIOS);
- a toolchain do FPGA Gowin (para a Tang Primer 20K): **Gowin IDE** com `gw_sh`;
- `openFPGALoader` (ou o loader do Gowin) para gravar o bitstream.

Aponte o LiteX para **este** checkout do VexiiRiscv (para usar a config/plugins
deste repo, ex.: Zbb). O wrapper procura o diretório do VexiiRiscv; use a
variável de ambiente do wrapper (ex.: `VEXIIRISCV`/`--cpu-variant`+`--vexii-args`)
ou clone conforme a doc do LiteX. Referência de fluxo VexiiRiscv+LiteX (buildroot):
`doc/litex/buildroot/README.md` deste repo.

### Passo 2 — Integrar o ML-KEM no BIOS do LiteX

Reaproveite os arquivos de `../VexRiscvPQC/litex_sipeed_mlkem_integration/`
(são CPU-agnósticos):
- `bios/mlkem_litex.c` — roda keypair/encaps/decaps, valida o KAT e imprime
  `[MLKEM] … KAT PASS` pela UART, medindo ciclos com o `timer0`;
- `bios/mlkem_native_litex_config.h` — config bare-metal do `mlkem-native`
  (`NO_ASM`, MLKEM-512, namespace `mlkem`);
- `bios/kat_vectors.h` — vetores KAT (idênticos aos da simulação);
- `bios/Makefile` e `patches/main.c.patch` — compila `mlkem_litex.o`/
  `mlkem_native.o` e mostra onde chamar a rotina no boot do BIOS;
- `scripts/install_into_litex.sh` — copia esses arquivos para dentro do checkout
  do LiteX.

O `external/mlkem-native` deste repo é o mesmo submódulo, então os fontes do
algoritmo são reaproveitados sem mudança.

### Passo 3 — Gerar e gravar o bitstream (VexiiRiscv)

Adaptado do fluxo validado da referência, trocando o CPU de `vexriscv`
(32-bit minimal) para **`vexiiriscv`**:

```bash
# ambiente Gowin (ajuste o caminho da sua instalação)
export GOWIN_HOME=/opt/Gowin/IDE
export PATH=$GOWIN_HOME/bin:$PATH

rm -rf build/sipeed_tang_primer_20k

python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv \
  --cpu-variant=standard \
  --vexii-args="--with-mul --with-div --allow-bypass-from=0" \
  --uart-name=serial \
  --integrated-rom-size=0xc000 \
  --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  --build \
  --load
```
Notas (herdadas da integração de referência):
- `--integrated-main-ram-size=0x100` evita ligar a DDR/LiteDRAM (usar `0x0`
  ativaria o caminho com DRAM).
- `--integrated-sram-size=0x8000` deixa folga para o ML-KEM-512 e a stack.
- `--integrated-rom-size` deve caber o BIOS + o código do ML-KEM.
- `--vexii-args="..."` é onde entram as extensões/otimizações do core. Ex.: para
  experimentar bit-manipulation (ver `understanding/plano_aceleracao.md`),
  acrescente `--with-rvZbb --with-rvZba` **e** garanta que o BIOS seja compilado
  com um `-march` que inclua `zbb` (core e firmware sempre com a **mesma** ISA).
- A ISA gerada pelo core precisa casar com o `-march`/`-mabi` do BIOS. Confirme
  o march default do wrapper (`rv32i…`/`rv64i…`) e ajuste o Makefile do BIOS.

### Passo 4 — Ler a saída pela UART

Em outro terminal (porta validada na referência: `/dev/ttyUSB1`):
```bash
python3 -m litex.tools.litex_term /dev/ttyUSB1 --speed 115200
# se corromper no reset/load, use raw:
python3 -m serial.tools.miniterm /dev/ttyUSB1 115200 --raw
```

Saída esperada (formato da integração de referência):
```text
[MLKEM] ML-KEM-512 KAT start
[MLKEM] bench_keypair_cycles=...
[MLKEM] bench_encaps_cycles=...
[MLKEM] bench_decaps_cycles=...
[MLKEM] KAT PASS
```
Converter ciclos em tempo (com o clock do SoC, ex.: 48 MHz):
```text
tempo_ms = cycles * 1000 / clock_hz
```

### Diferenças em relação ao fluxo da referência (VexRiscv 32-bit)
| | Referência (`../VexRiscvPQC`) | Este repo (VexiiRiscv) |
|---|---|---|
| `--cpu-type` | `vexriscv` | **`vexiiriscv`** |
| `--cpu-variant` | `minimal` | `standard` (ou `cached`/`linux`) |
| Geração do core | wrapper VexRiscv | `sbt runMain vexiiriscv.soc.litex.SocGen` |
| Config extra do core | limitada | **`--vexii-args="..."`** (plugins/extensões) |
| BIOS/ML-KEM | integração CPU-agnóstica | **a mesma** (reaproveitável) |
| Largura | 32-bit (`rv32i…`) | 64-bit (`rv64i…`) ou 32-bit, conforme variant |

> Status: o fluxo de **simulação** deste guia foi executado e validado neste
> repositório. O fluxo de **placa** é documentado a partir da integração de
> referência e da documentação oficial do LiteX/VexiiRiscv; ajuste caminhos,
> variant e `-march` do BIOS ao seu hardware antes de gravar.

---

## Fontes

- LiteX (setup e targets de placa): https://github.com/enjoy-digital/litex
- Wrapper LiteX do VexiiRiscv (variants, `--vexii-args`, `SocGen`):
  https://github.com/enjoy-digital/litex/blob/master/litex/soc/cores/cpu/vexiiriscv/core.py
- Fluxo VexiiRiscv+LiteX (buildroot) neste repo: `doc/litex/buildroot/README.md`
- Integração ML-KEM no BIOS (referência):
  `../VexRiscvPQC/litex_sipeed_mlkem_integration/`
- Tang Primer 20K (LiteX): https://github.com/enjoy-digital/litex/issues/1750
