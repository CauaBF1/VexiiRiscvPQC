# Profiling hospedado do ML-KEM-512 com GNU GPROF

Este harness usa o `gprof` para descobrir funções quentes e caminhos de chamadas
sem substituir as medições de ciclos no VexiiRiscv. O resultado principal usa a
implementação C portátil; `-O2`, build sem inlining e backend x86 nativo são
controles metodológicos.

## Execução

```bash
make -C src/main/c/host/mlkem512_gprof check
make -C src/main/c/host/mlkem512_gprof build
make -C src/main/c/host/mlkem512_gprof test
make -C src/main/c/host/mlkem512_gprof profile PROFILE_SECONDS=5 PROFILE_RUNS=3
make -C src/main/c/host/mlkem512_gprof report
```

Os resultados são gravados em `understanding/benchmarks/gprof/<data-hora>/`.
Essa árvore é privada e ignorada pelo Git. O manifesto registra caminhos e hashes
dos ELFs e bibliotecas arquivados em `<variante>/artifacts/`; o diretório também
contém os arquivos `gmon`, perfis individuais/agregados, CSV/JSON, relatório
Markdown e disassembly GDB dos cinco primeiros candidatos.

Para inspecionar outro símbolo:

```bash
make -C src/main/c/host/mlkem512_gprof inspect \
  SYMBOL=PQCP_MLKEM_NATIVE_MLKEM512_poly_ntt
```

## Interpretação

- `c-os`: ranking principal, próximo da otimização do firmware Vexii.
- `c-o2`: sensibilidade ao nível de otimização.
- `c-noinline`: call graph e chamadas; seus percentuais não representam desempenho.
- `native-o2`: controle de viés do host; não orienta diretamente o RTL do RV32.

O relatório separa `primary-hotspot` (símbolo medido no C `-Os`) de
`structural-noinline` (função que só ficou visível ao desabilitar inlining). Para
um símbolo estrutural, a inspeção GDB escolhe automaticamente o ELF
`c-noinline`; para os demais, usa o ELF principal `c-os`.

Um hotspot do host só vira candidato de hardware depois de ser localizado no
assembly RISC-V e confirmado por `rdcycle`/timer no Vexii. O teto de Amdahl gerado
no CSV é explicitamente uma estimativa do host.
