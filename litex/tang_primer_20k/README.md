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
`bios/mlkem_accel_select.h`, `bios/kat_vectors.h`) e o backend compartilhado
`src/main/c/vexii/mlkem512/src/mlkem_keccak_vexii.h` usam apenas APIs do LiteX
(`csr.h`, `timer0`, `printf`) e as APIs *derand* do `mlkem-native`. São os mesmos
da integração de referência (VexRiscv 32-bit); o que muda é o SoC gerado com
`--cpu-type=vexiiriscv`.

## Fluxo após `git pull` (no PC da placa)

No computador onde a Tang está conectada, com o LiteX já clonado (ex.: `~/litex`):

```bash
cd ~/VexiiRiscvPQC        # este repo
git pull
LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --patch-litex
LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --check
MLKEM_ACCEL=all LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh
```

O `deploy.sh` faz tudo, de forma **idempotente** (pode rodar de novo sem quebrar):

1. pela ação explícita `--patch-litex`, faz o wrapper usar este checkout do
   VexiiRiscv (com backup e sem atualizar repositórios pela rede);
2. valida dependências, patches externos, BIOS e o patch do `mlkem-native`;
3. inicializa o submódulo quando necessário e aplica `make prep` idempotentemente;
4. copia os arquivos ML-KEM e a configuração HW/SW para o BIOS;
5. faz *patch* no `Makefile` do BIOS (injeta o caminho do `mlkem-native` **deste**
   repo e adiciona os objetos) e no `main.c` (chama o ML-KEM no boot) — com backup
   `*.pre-mlkem`;
6. gera o SoC VexiiRiscv e grava na placa
   (`--cpu-type=vexiiriscv --build --load`).

Ler a UART (outro terminal):
```bash
python3 -m litex.tools.litex_term /dev/ttyUSB2 --speed 115200
# se corromper: python3 -m serial.tools.miniterm /dev/ttyUSB2 115200 --raw
```

### Variáveis (todas com default)
| Var | Default | Para quê |
|---|---|---|
| `LITEX_DIR` | `~/litex` | raiz do LiteX clonado (contém `litex/`, `litex-boards/`, …) |
| `CPU_VARIANT` | `standard` | variant VexiiRiscv no LiteX (`standard`/`cached`/`linux`) |
| `VEXII_ARGS` | vazio | flags opcionais do gerador do core (ex.: `--with-btb --with-ras --with-gshare`) |
| `MLKEM_ACCEL` | `none` | seleciona `none`, `montmul`, `montred`, `both`, `keccak`, `montmul-keccak`, `montred-keccak` ou `all` no HW e SW |
| `MLKEM_HW`/`MLKEM_SW` | — | modo avançado; devem ser informados juntos e o SW deve ser subconjunto do HW |
| `MLKEM_BUILD_DIR` | automático | sobrescreve `~/litex/build/mlkem_hw_<HW>_sw_<SW>` |
| `UART_DEV` | `/dev/ttyUSB2` | porta serial observada no vlab; ajuste em outra máquina |

### Modos
```bash
./litex/tang_primer_20k/deploy.sh --check     # só valida o ambiente; não copia/builda
./litex/tang_primer_20k/deploy.sh --patch-litex # patch explícito do core.py externo
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

O preflight não modifica checkouts externos. O patch que seleciona este gerador
é aplicado somente por `--patch-litex`; as correções legadas das flags e do reset
da placa continuam detectadas, mas não são aplicadas automaticamente.

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

As instruções `montmul`/`montred` e a unidade stateful Keccak-f[1600] são opções
de `ParamSimple` e chegam ao `SocGen` por `--with-montmul`, `--with-montred` e
`--with-keccak`. O Keccak usa quatro instruções em `custom-2`: KWRITE/KREAD
transferem as 50 palavras de 32 bits, KPERM executa 24 rodadas e KCLEAR apaga o
estado interno. Use os seletores `MLKEM_*` do deploy: passar essas flags
diretamente em `VEXII_ARGS` é rejeitado para impedir hardware e firmware
divergentes.

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

## Executar no vlab

O baseline `none` já produziu `KAT PASS` na placa. A campanha abaixo mantém
rv32im, 48 MHz, ROM/SRAM e firmware determinístico; somente os seletores dos
aceleradores variam.

**1. Preparar o ambiente e o gerador local:**

```bash
ssh vlab
cd ~/VexiiRiscvPQC
git pull --ff-only origin dev
git submodule update --init --recursive

source ~/litex-env/bin/activate
export PYTHONPATH="$HOME/litex/litex:$HOME/litex/litex-boards"
export GOWIN_HOME=/var/local/Gowin_V1.9.10.03_Education_linux/IDE
export PATH="$GOWIN_HOME/bin:$PATH"
export LD_PRELOAD=/lib/x86_64-linux-gnu/libfreetype.so.6

LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --patch-litex
LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --check
```

**2. Abrir a UART antes de gravar:**

```bash
cd /
source ~/litex-env/bin/activate
python3 -m serial.tools.miniterm /dev/ttyUSB2 115200 --raw
```

**3. Executar as configurações principais, uma por vez:**

```bash
MLKEM_ACCEL=none     LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=montmul  LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=montred  LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=both     LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=keccak   LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=all      LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
```

Para comparar somente o código emitido mantendo ambos os plugins no core:

```bash
MLKEM_HW=both MLKEM_SW=none     LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=both MLKEM_SW=montmul  LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=both MLKEM_SW=montred  LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=both MLKEM_SW=both     LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
```

Para isolar Keccak mantendo exatamente o mesmo hardware completo:

```bash
MLKEM_HW=all MLKEM_SW=both      LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=all MLKEM_SW=keccak    LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=all MLKEM_SW=all       LITEX_DIR=~/litex ./litex/tang_primer_20k/deploy.sh --all
```

Cada combinação fica em `~/litex/build/mlkem_hw_<HW>_sw_<SW>/` e contém
`mlkem_build_manifest.md`. Na UART, confirme `hw_accel`, `sw_accel`, todos os
matches, `status=0x00f00d` e `KAT PASS`. Leia área/Fmax nos relatórios listados
no manifesto.

Rollback somente do patch deste projeto:

```bash
git -C ~/litex/litex apply --reverse \
  ~/VexiiRiscvPQC/litex/tang_primer_20k/patches/vexiiriscv_local_generator.patch
```

## Status

- O fluxo VexiiRiscv rv32im produziu `KAT PASS` na Tang Primer 20K no vlab.
- `montmul`/`montred` estão integrados ao parser, `SocGen`, firmware e deploy.
- Keccak está integrado ao parser, RTL, hook FIPS-202 x1, firmware e deploy; os
  testes diferenciais e KAT local passam. Em simulação, `keccak` atingiu `1,252x`
  e `all` `1,597x` contra o baseline pela mediana de cinco execuções.
- Área, Fmax, ciclos e KAT dos bitstreams Keccak ainda precisam ser preenchidos
  após a campanha no vlab; o clock impresso na UART não substitui o relatório de
  timing do Gowin.
