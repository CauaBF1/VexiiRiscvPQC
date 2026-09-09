# ML-KEM-512 no VexiiRiscv (simulação rv64 e FPGA rv32)

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
- `gcc`, `gprof` e `gdb` GNU no host Linux/glibc (campanha de profiling hospedada)
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
MABI  ?= lp64
MARCH ?= rv64imac_zicsr
```
Ajuste `RISCV_PATH`/`RISCV_NAME` se sua toolchain estiver em outro lugar.

---

## Preparar o repositório

### 1. Clonar (com submódulos)

```bash
# clone novo, já trazendo todos os submódulos:
git clone --recursive <url-deste-repo>

# OU, se já clonou sem --recursive, inicialize os submódulos:
git submodule update --init external/mlkem-native      # algoritmo ML-KEM-512
git submodule update --init ext/SpinalHDL ext/rvls      # simulação (SpinalHDL + bindings rvls)
```

### 2. Trazer/atualizar o `external/mlkem-native`

O submódulo fica **fixado no commit LIMPO do upstream** (pq-code-package/mlkem-native);
o repo pai só guarda o ponteiro (SHA + URL). Para buscar/atualizar o conteúdo dele:

```bash
# checa out o commit que o repo pai fixa (o normal após clonar ou dar pull no pai):
git submodule update --init external/mlkem-native

# se quiser puxar as últimas mudanças do próprio mlkem-native (avança o ponteiro):
git submodule update --remote external/mlkem-native
```

### 3. Aplicar nosso patch (montmul + montred + profiling)

Nossas edições no mlkem-native (os hooks `.insn` de **`montmul`**/`montred`, os
brackets de profiling Keccak/NTT e os fallbacks no-op em `common.h`) **não** vivem no submódulo —
vivem no patch versionado `external/mlkem-native.patch`, aplicado por cima do
checkout limpo. Um único patch cobre os dois (montmul depende da mesma árvore).

```bash
make -C src/main/c/vexii/mlkem512 prep      # aplica o patch (idempotente)
make -C src/main/c/vexii/mlkem512 unprep    # reverte o patch, se precisar
```

> - `prep` é **idempotente**: rodar de novo detecta que já está aplicado e não faz nada.
> - Depois do `prep`, `git status` mostra `external/mlkem-native` como *modificado*
>   (` m`) — **é esperado** (é o patch na árvore de trabalho). **Não commite o
>   submódulo**; para status limpo, `unprep`.
> - Se você atualizar o submódulo (passo 2) e o patch não aplicar mais, **regere-o**:
>   `git -C external/mlkem-native diff > external/mlkem-native.patch`.
> - Sem `make prep` o build ainda funciona, mas usa o mlkem-native **de fábrica**.
> - Com o patch e sem `-DMLK_PROFILE`, os hooks viram statements no-op: não mudam
>   o código executável/comportamento. O ELF completo pode diferir por metadados `-g`.

### 4. (opcional) Ligar as acelerações no build

Com o patch aplicado, compile passando o define pra rotear `mlk_fqmul` pela
instrução `montmul` (ver `understanding/benchmarks/montmul/`):

```bash
make -C src/main/c/vexii/mlkem512 CFLAGS_EXTRA=-DMLK_USE_MONTMUL all
```

Para ligar as duas instruções:

```bash
make -C src/main/c/vexii/mlkem512 \
  CFLAGS_EXTRA='-DMLK_USE_MONTMUL -DMLK_USE_MONTRED' all
sbt "runMain vexiiriscv.execute.VexiiMontSim \
  --load-elf src/main/c/vexii/mlkem512/build/mlkem512.elf \
  --xlen 64 --with-rvm --with-rvc --performance-counters 0 \
  --reset-vector 2147483648 --no-rvls-check"
```

O `TestBench` padrão não instancia essas instruções; use `VexiiMontmulSim` para
`montmul` isolado e `VexiiMontSim` para qualquer combinação com `montred`.

Para ligar somente a permutação Keccak-f[1600]:

```bash
make -B -C src/main/c/vexii/mlkem512 KAT=yes \
  CFLAGS_EXTRA=-DMLK_USE_KECCAK all
sbt "runMain vexiiriscv.tester.TestBench \
  --load-elf src/main/c/vexii/mlkem512/build/mlkem512.elf \
  --xlen 64 --with-rvm --with-rvc --with-keccak \
  --performance-counters 0 --reset-vector 2147483648 \
  --no-rvls-check --no-stdin"
```

Para ligar Montgomery e Keccak juntos, use os três defines no firmware e as
três opções no core:

```bash
make -B -C src/main/c/vexii/mlkem512 KAT=yes \
  CFLAGS_EXTRA='-DMLK_USE_MONTMUL -DMLK_USE_MONTRED -DMLK_USE_KECCAK' all
sbt "runMain vexiiriscv.tester.TestBench \
  --load-elf src/main/c/vexii/mlkem512/build/mlkem512.elf \
  --xlen 64 --with-rvm --with-rvc \
  --with-montmul --with-montred --with-keccak \
  --performance-counters 0 --reset-vector 2147483648 \
  --no-rvls-check --no-stdin"
```

O backend Keccak usa o hook FIPS-202 x1 oficial do `mlkem-native`; ele não faz
parte de `external/mlkem-native.patch`. `MLK_USE_KECCAK` é incompatível com
`MLK_CONFIG_NO_ASM`, por isso os headers de configuração escolhem um ou outro.

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

## Descobrir alvos de aceleração com GCC + GPROF + GDB

O profiling GNU é executado no **PC host**, não no firmware bare-metal. A
toolchain RISC-V desta configuração não possui o runtime `gmon`
(`gcrt0.o`/`libgmon.a` e `_mcount`) necessário ao `-pg`. Portanto, o método é
híbrido:

1. GCC e GPROF localizam funções quentes e relações de chamada na mesma
   implementação C portátil do ML-KEM-512;
2. GDB confirma símbolos, fonte e assembly dos candidatos;
3. os buckets `rdcycle` e o KAT no Vexii confirmam se o candidato também é
   relevante e correto na arquitetura RV32/RV64.

O harness está em `src/main/c/host/mlkem512_gprof/`. Execute a partir da raiz:

```bash
# ambiente, versões, commits, patch e disponibilidade de moncontrol()
make -C src/main/c/host/mlkem512_gprof check

# testes do parser e compilação das quatro variantes
make -C src/main/c/host/mlkem512_gprof test
make -C src/main/c/host/mlkem512_gprof build

# campanha recomendada: 5 s por amostra, 3 repetições por operação/variante
make -C src/main/c/host/mlkem512_gprof profile \
  PROFILE_SECONDS=5 PROFILE_RUNS=3

# normaliza resultados e gera ranking, tabelas e inspeções GDB
make -C src/main/c/host/mlkem512_gprof report
```

Cada execução mede separadamente `keypair`, `encaps`, `decaps` e o fluxo `all`.
Setup, warmup e validação ficam fora da janela do `gprof` por meio de
`moncontrol(0/1)`. As entradas são determinísticas e cada processo verifica o
shared secret antes de retornar `PASS`.

As quatro variantes têm papéis diferentes:

| variante | backend/flags | uso correto |
|---|---|---|
| `c-os` | C portátil, `-Os -g -pg` | ranking principal; mais próximo do firmware Vexii otimizado para tamanho |
| `c-o2` | C portátil, `-O2 -g -pg` | verificar sensibilidade ao otimizador |
| `c-noinline` | C portátil, `-O2 -pg -fno-inline...` | revelar `mlk_fqmul`, reduções e contagens escondidas por inlining; não comparar seu tempo como desempenho |
| `native-o2` | backend nativo x86/AVX2 | controle de viés do host; nunca projetar o ganho RV32 a partir dele |

Os resultados privados ficam em
`understanding/benchmarks/gprof/<AAAAMMDD-HHMMSS>/`. O `manifest.json` registra
commits, ferramentas, flags, hashes e todas as execuções. Em cada pasta há o
ELF/biblioteca arquivados, `gmon` bruto, stdout, flat profile, call graph e perfil
por linha; na raiz ficam `REPORT.md`, `candidates.csv/json` e `gdb/`.

Para inspecionar manualmente uma função do relatório:

```bash
make -C src/main/c/host/mlkem512_gprof inspect \
  SYMBOL=mlk_fqmul
```

Se houver um ELF RISC-V já compilado e `riscv64-unknown-elf-gdb` estiver no
`PATH`, também é possível correlacionar símbolos ao gerar o relatório:

```bash
make -C src/main/c/host/mlkem512_gprof report \
  RISCV_ELF="$PWD/src/main/c/vexii/mlkem512/build/mlkem512.elf"
```

Interprete `self %` como participação no tempo amostrado **daquele binário no
host**. `primary-hotspot` é visível no C `-Os`; `structural-noinline` só ficou
isolável sem inlining. O score de candidato mistura tempo, frequência,
reutilização e duas heurísticas de hardware: ele ajuda a priorizar inspeção, mas
não autoriza sozinho um novo plugin RTL. A confirmação final continua sendo
assembly/ciclos no Vexii, KAT, síntese, área e Fmax.

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

## Executar Montgomery e Keccak na placa pelo vlab com `deploy.sh`

Este é o fluxo completo executado em 2026-08-26 e 2026-08-27 na Tang Primer
20K. O baseline e os bitstreams com `montmul`, `montred` e ambos foram gerados,
carregados na SRAM da FPGA e terminaram com `[MLKEM] KAT PASS`. O ambiente
validado usa:

```text
repositório:  ~/VexiiRiscvPQC
LiteX:        ~/litex
venv:         ~/litex-env
placa:        Tang Primer 20K / GW2A-LV18PG256C8/I7
CPU:          VexiiRiscv rv32im, 48 MHz
UART:         /dev/ttyUSB2, 115200 8N1
```

Commits registrados na execução de referência do baseline de 2026-08-26:

| componente | commit |
|---|---|
| VexiiRiscvPQC | `cd59cd6` |
| mlkem-native | `e29c3900b81e196e09b0f0957cf29d628ba5eb56` |
| LiteX | `97d81467881f` |
| LiteX-Boards | `3e1d57ad189f` |
| VexiiRiscv usado pelo gerador no baseline | `235753e24f2d960e49a0852205bae1400bf22c19` |

Na campanha Montgomery de 2026-08-27, o gerador passou a usar este checkout via
`MLKEM_REPO_DIR`. Seu commit exato deve ser lido no `mlkem_build_manifest.md` de
cada configuração; o manifesto é a fonte autoritativa quando houver diferença
em relação ao baseline histórico acima.

O `deploy.sh` é o ponto de entrada recomendado. Ele valida o ambiente antes de
alterar o BIOS, aplica o patch versionado do `mlkem-native` de forma idempotente,
copia a integração, compila, sintetiza e opcionalmente carrega o bitstream.

O baseline valida o ML-KEM sem instruções customizadas. A campanha de 2026-08-27
validou na placa a integração completa dos plugins RTL ao `SocGen`, dos hooks
`.insn` ao firmware e da seleção HW/SW ao deploy. Os resultados de ciclos estão
registrados na seção 5; área, slack e Fmax ainda devem ser extraídos dos
relatórios do Gowin antes de encerrar a comparação física.

### 0. Atualizar o repositório e aplicar o patch

Em um checkout antigo, a regra `unprep` pode ainda não existir. Se
`git -C external/mlkem-native status --short` não imprimir nada, faça diretamente:

```bash
ssh vlab
cd ~/VexiiRiscvPQC

git pull --ff-only origin dev
git submodule update --init --recursive
make -C src/main/c/vexii/mlkem512 prep
git status --short
```

Depois de `prep`, é esperado que o status mostre:

```text
 m external/mlkem-native
```

O gitlink do submódulo permanece no commit upstream; as alterações são
transportadas por `external/mlkem-native.patch`. Não execute `git add` no
submódulo.

Nos próximos pulls, quando a regra já existir, reverta o patch antigo antes de
atualizar e aplique o novo depois:

```bash
cd ~/VexiiRiscvPQC
make -C src/main/c/vexii/mlkem512 unprep
git pull --ff-only origin dev
git submodule update --init --recursive
make -C src/main/c/vexii/mlkem512 prep
```

Se o submódulo tiver mudanças que não sejam o patch conhecido, pare e inspecione
antes do pull. Não use `git reset --hard` para resolver esse estado.

### 1. Preparar LiteX, Gowin e ferramentas

Em cada terminal usado para build/load:

```bash
source ~/litex-env/bin/activate

cd ~/litex
export PYTHONPATH="$PWD/litex:$PWD/litex-boards"
export GOWIN_HOME=/var/local/Gowin_V1.9.10.03_Education_linux/IDE
export PATH="$GOWIN_HOME/bin:$PATH"
export LD_PRELOAD=/lib/x86_64-linux-gnu/libfreetype.so.6

python3 -c 'import litex, litex_boards; print("LiteX OK")'
command -v meson
command -v ninja
command -v gw_sh
command -v openFPGALoader
```

### 2. Aplicar o patch explícito do gerador e rodar o preflight

```bash
cd ~/VexiiRiscvPQC
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --patch-litex
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --check
```

`--patch-litex` é a única ação que modifica o checkout externo: cria um backup e
aplica o patch versionado que faz `PythonArgsGen` e `SocGen` usarem este repo via
`MLKEM_REPO_DIR`. A ação é idempotente e aceita o commit LiteX validado
`97d81467881f...`. O `--check` continua somente leitura e confirma que não haverá
fallback para o gerador de `pythondata-cpu-vexiiriscv`.

Se ele acusar flags legadas ou segundo driver de reset, o checkout externo foi
recriado e perdeu os patches. Aplique somente a correção indicada e repita o
preflight:

```bash
# Patch externo 1: remover flags rejeitadas pelo parser isamap.
sed -i 's/ --with-mul --with-div --allow-bypass-from=0/ --allow-bypass-from=0/' \
  ~/litex/litex/litex/soc/cores/cpu/vexiiriscv/core.py

# Patch externo 3: remover o segundo driver de sys_rst incompatível com Gowin.
sed -i 's@self.specials += AsyncResetSynchronizer(self.cd_sys, ~pll.locked | self.rst | self.reset)@#&@' \
  ~/litex/litex-boards/litex_boards/targets/sipeed_tang_primer_20k.py

# Dependências do BIOS no venv, se estiverem ausentes.
python3 -m pip install meson ninja
```

O patch local do gerador é aplicado apenas pela ação explícita `--patch-litex`.
As correções das flags legadas e do reset da placa continuam manuais: o deploy
apenas as detecta e falha antes de tocar no BIOS.

### 3. Abrir a UART no terminal A — antes do load

O ML-KEM imprime uma única vez no boot. Se as portas FTDI não existirem:

```bash
sudo modprobe -r ftdi_sio && sudo modprobe ftdi_sio
ls /dev/ttyUSB*
```

Para identificar o canal em vez de tentar portas aleatórias:

```bash
for dev in /dev/ttyUSB*; do
  echo "=== $dev ==="
  udevadm info -q property -n "$dev" \
    | grep -E '^(ID_SERIAL=|ID_MODEL=|ID_USB_INTERFACE_NUM=|ID_PATH=)'
done
```

No vlab validado, o canal B/UART é `/dev/ttyUSB2`. Use `miniterm` em modo raw:

```bash
cd /
source ~/litex-env/bin/activate
python3 -m serial.tools.miniterm /dev/ttyUSB2 115200 --raw
```

Executar a partir de `/` evita que o diretório agregador `~/litex` seja importado
como pacote namespace. Se preferir `litex_term`, fixe explicitamente os caminhos:

```bash
cd /
source ~/litex-env/bin/activate
export PYTHONPATH="$HOME/litex/litex:$HOME/litex/litex-boards"
python3 -m litex.tools.litex_term /dev/ttyUSB2 --speed 115200
```

Não abra o canal A/JTAG como terminal serial enquanto o `openFPGALoader` estiver
programando a placa.

### 4. Build e load dos aceleradores pelo `deploy.sh` no terminal B

Com o ambiente da etapa 1 ativo e a UART aguardando, o seletor aceita `none`,
`montmul`, `montred`, `both`, `keccak`, `montmul-keccak`, `montred-keccak` ou
`all`. `both` continua significando `montmul+montred`; `all` ativa as três
features. No modo simples, a mesma combinação entra no RTL e no firmware.

```bash
cd ~/VexiiRiscvPQC
MLKEM_ACCEL=none    LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=montmul LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=montred LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=both    LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=keccak  LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_ACCEL=all     LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
```

Cada comando gera hardware, firmware e diretório próprios:

| `MLKEM_ACCEL` | plugins no core | instruções emitidas pelo firmware | diretório |
|---|---|---|---|
| `none` | nenhum | nenhuma | `~/litex/build/mlkem_hw_none_sw_none/` |
| `montmul` | `MontMulPlugin` | `montmul` | `~/litex/build/mlkem_hw_montmul_sw_montmul/` |
| `montred` | `MontRedPlugin` | `montred` | `~/litex/build/mlkem_hw_montred_sw_montred/` |
| `both` | ambos | ambas | `~/litex/build/mlkem_hw_both_sw_both/` |
| `keccak` | `KeccakPlugin` | KWRITE/KREAD/KPERM/KCLEAR | `~/litex/build/mlkem_hw_keccak_sw_keccak/` |
| `all` | três plugins | Montgomery + Keccak | `~/litex/build/mlkem_hw_all_sw_all/` |

O `deploy.sh` passa as opções de hardware ao `SocGen`, gera no BIOS o header com
as opções de software, força `--no-netlist-cache` e grava no manifesto os commits,
flags e hash do bitstream. `VEXII_ARGS` deve ficar vazio durante esta campanha.

Depois da campanha casada, mantenha exatamente o mesmo core com todos os plugins
e varie somente as instruções usadas pelo firmware. Esta é a matriz recomendada
para isolar o efeito do código emitido:

```bash
MLKEM_HW=both MLKEM_SW=none     LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=both MLKEM_SW=montmul  LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=both MLKEM_SW=montred  LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=both MLKEM_SW=both     LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=all  MLKEM_SW=both     LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=all  MLKEM_SW=keccak   LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
MLKEM_HW=all  MLKEM_SW=all      LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
```

O script rejeita qualquer `MLKEM_SW` que não seja subconjunto de `MLKEM_HW`.
Não coloque `--with-montmul`, `--with-montred` ou `--with-keccak` em
`VEXII_ARGS`; o deploy deriva essas opções de `MLKEM_HW` e gera o header do
firmware correspondente.

O sucesso do deploy exige, no log:

```text
Preflight concluído
mlkem-native patch already applied
CC       mlkem_litex.o
CC       mlkem_native.o
GowinSynthesis finish
Placement and routing completed
Bitstream generation completed
Load SRAM: 100.00%
DONE
```

No build validado, a ROM ficou próxima do limite:

```text
ROM usage:  30.97 KiB / 32 KiB (96.78%)
SRAM usage:  3.51 KiB / 32 KiB (10.96%)
```

Novas instrumentações devem conferir se o BIOS continua cabendo em `0x8000`.

### 5. Verificar a saída e comparar os ciclos

Para cada configuração, confirme primeiro que a UART identifica o par correto:

```text
[MLKEM] hw_accel=<none|montmul|montred|both|keccak|montmul-keccak|montred-keccak|all>
[MLKEM] sw_accel=<none|montmul|montred|both|keccak|montmul-keccak|montred-keccak|all>
```

O veredito só é positivo quando todas estas linhas aparecem:

```text
[MLKEM] ML-KEM-512 KAT start
[MLKEM] keypair: ok
[MLKEM] bench_keypair_cycles=...
[MLKEM] encaps: ok
[MLKEM] bench_encaps_cycles=...
[MLKEM] decaps: ok
[MLKEM] bench_decaps_cycles=...
[MLKEM] ss self-match: ok
[MLKEM] pk match: ok
[MLKEM] sk match: ok
[MLKEM] ct match: ok
[MLKEM] ss match: ok
[MLKEM] status=0x00f00d
[MLKEM] KAT PASS
```

Resultados da primeira campanha física Montgomery, em 2026-08-27, a 48 MHz:

| configuração | keypair | encaps | decaps | soma | redução contra `none` | speedup |
|---|---:|---:|---:|---:|---:|---:|
| `none` | 935.924 | 1.073.320 | 1.356.983 | 3.366.227 | — | 1,000x |
| `montmul` | 877.986 | 1.000.665 | 1.246.168 | 3.124.819 | 7,172% | 1,077x |
| `montred` | 929.309 | 1.063.918 | 1.344.895 | 3.338.122 | 0,835% | 1,008x |
| `both` | 875.310 | 991.781 | 1.234.637 | 3.101.728 | 7,857% | 1,085x |

A soma considera apenas `keypair + encaps + decaps`. A configuração `both`
economizou 264.499 ciclos, ou aproximadamente 5,510 ms a 48 MHz. `montmul`
concentrou quase todo o ganho; acrescentar `montred` sobre `montmul` economizou
mais 23.091 ciclos, uma redução adicional de 0,739%.

Esses números confirmam corretude e desempenho para esta execução, mas não
substituem repetições. Para o relatório, recarregue cada bitstream pelo menos
cinco vezes, use a mediana e registre mínimo, máximo e variação percentual. Rode
também a matriz com `MLKEM_HW=both` para separar o efeito do firmware de diferenças
entre configurações do core.

Resultados locais do core saudável VexiiRiscv, cinco execuções por configuração
e mediana da soma `keypair + encaps + decaps`:

| configuração | keypair | encaps | decaps | soma | speedup contra `none` |
|---|---:|---:|---:|---:|---:|
| `none` | 334.952 | 455.480 | 601.315 | 1.391.687 | 1,000x |
| `both` | 282.898 | 375.950 | 479.982 | 1.138.830 | 1,222x |
| `keccak` | 250.556 | 368.978 | 492.390 | 1.111.882 | 1,252x |
| `all` | 198.104 | 294.174 | 379.117 | 871.246 | 1,597x |

O backend Keccak completo teve mediana de aproximadamente 396 ciclos por
permutação, incluindo 50 escritas, `KPERM`, 50 leituras e `KCLEAR`; a região C
equivalente teve aproximadamente 3.448 ciclos, ou `8,71x` de ganho local. Esses
resultados são de simulação e servem para demonstrar corretude e ganho em ciclos.
Eles não substituem os relatórios de área/timing nem as medições físicas da FPGA.

`BIOS CRC passed`, `Memtest OK` e o posterior `No boot medium found` são
compatíveis com a execução: o KAT já terminou e o BIOS apenas não encontrou uma
segunda imagem para carregar. A string padrão da ISA não mostra `montmul` ou
`montred`, pois elas ocupam o espaço RISC-V `custom-0` e não são extensões
padronizadas do `march`.

### 6. Recarregar sem ressintetizar e repetir medições

Com a UART aberta, é possível disparar novamente o boot usando o `.fs` existente.
Por exemplo, para `both`:

```bash
openFPGALoader --cable ft2232 \
  --bitstream ~/litex/build/mlkem_hw_both_sw_both/gateware/sipeed_tang_primer_20k.fs
```

Exemplos válidos são `mlkem_hw_none_sw_none`, `mlkem_hw_montmul_sw_montmul`,
`mlkem_hw_montred_sw_montred`, `mlkem_hw_both_sw_both`,
`mlkem_hw_keccak_sw_keccak` e `mlkem_hw_all_sw_all`. Recarregar o `.fs` não
ressintetiza o SoC e é o método indicado para medir a variação entre boots do
mesmo bitstream.

### 7. Coletar manifestos, área e timing

Cada diretório contém `mlkem_build_manifest.md`. Depois da campanha, liste os
manifestos e relatórios encontrados:

```bash
for dir in ~/litex/build/mlkem_hw_*_sw_*; do
  echo "=== $dir ==="
  sed -n '1,40p' "$dir/mlkem_build_manifest.md"
  find "$dir" -type f \
    \( -name '*.rpt' -o -name '*timing*' -o -name '*.html' \) -print
done
```

Não conclua que o timing fechou apenas porque a UART mostra `@ 48MHz`: isso é o
clock configurado. O relatório do Gowin deve confirmar slack, Fmax e caminho
crítico. Compare também LUTs, registradores e BSRAM contra o baseline. Variações
do `Memspeed` de apenas 256 bytes não devem ser tratadas como ganho ou regressão
do ML-KEM sem repetição específica.

### 8. Ações disponíveis

```bash
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --check
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --patch-litex
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --install
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --build
LITEX_DIR=~/litex bash litex/tang_primer_20k/deploy.sh --all
```

- `--check`: somente preflight;
- `--patch-litex`: aplica explicitamente o patch versionado do gerador local;
- `--install`: aplica `prep` e instala o ML-KEM no BIOS;
- `--build`: instala e sintetiza, sem carregar;
- `--all`: instala, sintetiza e carrega na SRAM da placa.

O deploy passa `--update-repo=no`, exporta `MLKEM_REPO_DIR` e usa
`--no-netlist-cache`. Assim, o log precisa mostrar o caminho deste checkout; não
há busca automática da branch `dev` nem fallback silencioso para o commit
empacotado em `pythondata`.

---

## Executar na placa Sipeed Tang Primer 20K com VexiiRiscv (via LiteX)

> ℹ️ O fluxo **provado** é o **"Executar na placa pelo vlab"** acima. A seção
> abaixo explica a integração e usa os mesmos defaults validados; prefira
> `litex/tang_primer_20k/deploy.sh` para executar o procedimento.

> **Este repositório NÃO instala o LiteX.** Esta seção documenta como fazer o
> setup inicial fora do vlab. Para executar no ambiente já preparado, não repita
> os comandos manuais desta seção: use o preflight e o `deploy.sh` da seção
> validada acima.

### Conceito (como o LiteX usa o VexiiRiscv)

O LiteX tem o VexiiRiscv como CPU de primeira classe: `--cpu-type=vexiiriscv`.
Ao gerar o SoC, o wrapper chama internamente:

```text
sbt "runMain vexiiriscv.soc.litex.SocGen <args>"
```

produzindo o Verilog do core. Flags específicas do VexiiRiscv (mesma família das
que passamos ao `TestBench`) são repassadas com **`--vexii-args="..."`**.

Sem o patch deste projeto, o comando é executado pelo checkout de VexiiRiscv
embutido em `pythondata-cpu-vexiiriscv`. A ação `deploy.sh --patch-litex` corrige
os dois pontos do wrapper (`PythonArgsGen` e `SocGen`) e valida
`MLKEM_REPO_DIR`; por isso os plugins deste fork passam a fazer parte da netlist.

- Variants aceitos pelo wrapper LiteX: `standard`, `cached`, `linux`, `debian`.
- march/mabi default: `rv{xlen}i…` + subconjunto `mafdc`; ABI `lp64`/`ilp32`.

**Importante — dois "firmwares" diferentes:**
O ELF de simulação em `src/main/c/vexii/mlkem512/` fala com o
`PeripheralEmulator` do testbench (`PUTC` em `0x10000000`, símbolos
`pass`/`fail`). **Ele não roda na placa.** Na placa, o ML-KEM roda como **app do
BIOS do LiteX**, usando a UART e o `timer0`. Os fontes em
`litex/tang_primer_20k/bios/` usam as APIs do LiteX, não o MMIO do simulador.

### Passo 1 — Instalar o LiteX (uma vez, fora deste repo)

Fonte oficial: `enjoy-digital/litex` (script `litex_setup.py`).
```bash
mkdir -p ~/litex && cd ~/litex
python3 -m venv ~/litex-env
source ~/litex-env/bin/activate
wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
chmod +x litex_setup.py
./litex_setup.py --init --install              # baixa/instala LiteX no venv ativo
python3 -m pip install meson ninja pyserial
```
Também são necessários:
- toolchain RISC-V (a mesma bare-metal serve para o BIOS);
- a toolchain do FPGA Gowin (para a Tang Primer 20K): **Gowin IDE** com `gw_sh`;
- `openFPGALoader` (ou o loader do Gowin) para gravar o bitstream.

O setup padrão instala `pythondata-cpu-vexiiriscv`. Não copie arquivos Scala para
esse pacote: aplique o patch versionado com `deploy.sh --patch-litex` e confirme o
caminho local no preflight.

### Passo 2 — Integrar o ML-KEM no BIOS do LiteX

O `deploy.sh --install`, `--build` e `--all` fazem esta integração
automaticamente a partir de:

- `litex/tang_primer_20k/bios/mlkem_litex.c` — roda
  keypair/encaps/decaps, valida o KAT e imprime
  `[MLKEM] … KAT PASS` pela UART, medindo ciclos com o `timer0`;
- `litex/tang_primer_20k/bios/mlkem_native_litex_config.h` — configuração
  bare-metal do `mlkem-native`
  (`NO_ASM`, MLKEM-512, namespace `mlkem`);
- `litex/tang_primer_20k/bios/mlkem_accel_select.h` — default seguro e contrato
  entre instruções presentes no hardware e emitidas pelo firmware;
- `litex/tang_primer_20k/bios/kat_vectors.h` — vetores KAT;
- `external/mlkem-native.patch` — profiling e hooks das instruções customizadas.

O script também atualiza idempotentemente o Makefile e o `main.c` do BIOS, criando
backups `*.pre-mlkem`. Não faça essa cópia manualmente no fluxo normal.

O `external/mlkem-native` deste repo é o mesmo submódulo, então os fontes do
algoritmo são reaproveitados sem mudança.

### Passo 3 — Gerar e gravar o bitstream (VexiiRiscv)

O `deploy.sh` chama o seguinte fluxo do LiteX. A expansão abaixo pressupõe que o
BIOS já foi preparado para `HW=both, SW=both`; executá-la isoladamente com um
header antigo pode criar hardware e firmware incompatíveis. Use-a apenas para
diagnóstico e, no vlab, prefira `LITEX_DIR=~/litex .../deploy.sh --all`:

```bash
# ambiente Gowin (ajuste o caminho da sua instalação)
export GOWIN_HOME=/opt/Gowin/IDE
export PATH=$GOWIN_HOME/bin:$PATH
export MLKEM_REPO_DIR=~/VexiiRiscvPQC

python3 -m litex_boards.targets.sipeed_tang_primer_20k \
  --cpu-type=vexiiriscv \
  --cpu-variant=standard \
  --update-repo=no --no-netlist-cache \
  --vexii-args="--with-montmul --with-montred --with-keccak" \
  --uart-name=serial \
  --bios-console=disable --bios-lto \
  --integrated-rom-size=0x8000 \
  --integrated-sram-size=0x8000 \
  --integrated-main-ram-size=0x100 \
  --output-dir=~/litex/build/mlkem_hw_all_sw_all \
  --build \
  --load
```
Notas:
- `--integrated-main-ram-size=0x100` evita ligar a DDR/LiteDRAM (usar `0x0`
  ativaria o caminho com DRAM).
- `--integrated-sram-size=0x8000` deixa folga para o ML-KEM-512 e a stack.
- `--integrated-rom-size` deve caber o BIOS + o código do ML-KEM.
- O usuário deve deixar `VEXII_ARGS` vazio na campanha de aceleradores; o deploy
  gera internamente `--with-montmul`, `--with-montred` e `--with-keccak` a
  partir de `MLKEM_HW`. Não passe essas opções manualmente, pois o header do
  firmware também precisa corresponder ao hardware. Para experimentar
  bit-manipulation (ver `understanding/plano_aceleracao.md`),
  acrescente `--with-rvZbb --with-rvZba` **e** garanta que o BIOS seja compilado
  com um `-march` que inclua `zbb` (core e firmware sempre com a **mesma** ISA).
- A ISA gerada pelo core precisa casar com o `-march`/`-mabi` do BIOS. Confirme
  o march default do wrapper (`rv32i…`/`rv64i…`) e ajuste o Makefile do BIOS.

### Passo 4 — Ler a saída pela UART

Em outro terminal (default validado no vlab: `/dev/ttyUSB2`; ajuste se necessário):
```bash
python3 -m litex.tools.litex_term /dev/ttyUSB2 --speed 115200
# se corromper no reset/load, use raw:
python3 -m serial.tools.miniterm /dev/ttyUSB2 115200 --raw
```

Saída esperada:
```text
[MLKEM] ML-KEM-512 KAT start
[MLKEM] hw_accel=<configuração de hardware>
[MLKEM] sw_accel=<configuração de firmware>
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

> Status: o baseline e as configurações físicas `montmul`, `montred` e `both`
> produziram `KAT PASS` na Tang Primer 20K a 48 MHz em 2026-08-27. A configuração
> `both` reduziu a soma dos três trechos medidos em 7,857%. A coleta consolidada
> de área, slack e Fmax nos relatórios do Gowin continua pendente. Localmente,
> `keccak` e `all` passaram no KAT integrado e `all` atingiu `1,597x` em ciclos;
> a síntese e a campanha física dessas duas configurações ainda estão pendentes.

---

## Fontes

- LiteX (setup e targets de placa): https://github.com/enjoy-digital/litex
- Wrapper LiteX do VexiiRiscv (variants, `--vexii-args`, `SocGen`):
  https://github.com/enjoy-digital/litex/blob/master/litex/soc/cores/cpu/vexiiriscv/core.py
- Fluxo VexiiRiscv+LiteX (buildroot) neste repo: `doc/litex/buildroot/README.md`
- Integração ML-KEM no BIOS e deploy: `litex/tang_primer_20k/`
- Tang Primer 20K (LiteX): https://github.com/enjoy-digital/litex/issues/1750
