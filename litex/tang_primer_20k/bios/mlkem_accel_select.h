#ifndef MLKEM_ACCEL_SELECT_H
#define MLKEM_ACCEL_SELECT_H

/* Safe default for manual/non-deploy builds: software-only ML-KEM. The deploy
 * writes a generated copy of this file into the external LiteX BIOS directory
 * for each selected hardware/software pair. */
#define MLKEM_HW_ACCEL_NAME "none"
#define MLKEM_SW_ACCEL_NAME "none"

#if defined(MLK_USE_MONTMUL) && !defined(MLK_HW_HAS_MONTMUL)
#error "MLK_USE_MONTMUL requires a VexiiRiscv core with MontMulPlugin"
#endif

#if defined(MLK_USE_MONTRED) && !defined(MLK_HW_HAS_MONTRED)
#error "MLK_USE_MONTRED requires a VexiiRiscv core with MontRedPlugin"
#endif

#if defined(MLK_USE_KECCAK) && !defined(MLK_HW_HAS_KECCAK)
#error "MLK_USE_KECCAK requires a VexiiRiscv core with KeccakPlugin"
#endif

#endif
