#ifndef MLKEM_KECCAK_VEXII_H
#define MLKEM_KECCAK_VEXII_H

/* mlkem-native FIPS-202 x1 backend for KeccakPlugin.
 *
 * The accelerator stores fifty RV32-sized words internally. Lanes are split
 * explicitly instead of aliasing uint64_t * as uint32_t *, keeping this valid
 * under strict aliasing and identical on RV32 and RV64.
 */
#define MLK_USE_FIPS202_X1_NATIVE

#if !defined(__ASSEMBLER__)
#include <stdint.h>
#include "src/fips202/native/api.h"

static MLK_INLINE void mlk_vexii_kwrite(uint32_t index, uint32_t word)
{
  __asm__ volatile(".insn r 0x5b, 0, 0, x0, %0, %1"
                   : : "r"(index), "r"(word) : "memory");
}

static MLK_INLINE uint32_t mlk_vexii_kread(uint32_t index)
{
  uint32_t word;
  __asm__ volatile(".insn r 0x5b, 1, 0, %0, %1, x0"
                   : "=r"(word) : "r"(index) : "memory");
  return word;
}

static MLK_INLINE void mlk_vexii_kperm(void)
{
  __asm__ volatile(".insn r 0x5b, 2, 0, x0, x0, x0" : : : "memory");
}

static MLK_INLINE void mlk_vexii_kclear(void)
{
  __asm__ volatile(".insn r 0x5b, 3, 0, x0, x0, x0" : : : "memory");
}

MLK_MUST_CHECK_RETURN_VALUE
static MLK_INLINE int mlk_keccak_f1600_x1_native(uint64_t *state)
{
  unsigned lane;
  /* The upstream C fallback is bracketed after the native early-return. Put
   * the same bucket around this backend so PROFILE=yes measures the complete
   * transfer + permutation + return protocol instead of reporting zero calls. */
  MLK_PROF_ENTER();

  for (lane = 0; lane < 25; lane++) {
    uint64_t value = state[lane];
    mlk_vexii_kwrite(2u * lane, (uint32_t)value);
    mlk_vexii_kwrite(2u * lane + 1u, (uint32_t)(value >> 32));
  }

  mlk_vexii_kperm();

  for (lane = 0; lane < 25; lane++) {
    uint64_t low = mlk_vexii_kread(2u * lane);
    uint64_t high = mlk_vexii_kread(2u * lane + 1u);
    state[lane] = low | (high << 32);
  }

  /* The state is not shared across calls and must not retain cryptographic
   * material after the result has returned to the caller. */
  mlk_vexii_kclear();
  MLK_PROF_EXIT(MLK_PB_KECCAK);
  return MLK_NATIVE_FUNC_SUCCESS;
}
#endif /* !__ASSEMBLER__ */

#endif /* MLKEM_KECCAK_VEXII_H */
