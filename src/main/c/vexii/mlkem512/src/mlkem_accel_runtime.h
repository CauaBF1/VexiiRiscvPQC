#ifndef MLKEM_ACCEL_RUNTIME_H
#define MLKEM_ACCEL_RUNTIME_H
#include <stdint.h>
/* Legacy: 0 C, 1 Montgomery, 2 Montgomery+Keccak.
 * MLK_RUNTIME_SELECTED: 0 C, 1 the compile-time MLK_USE_* profile. */
#ifdef MLK_RUNTIME_ACCEL
extern volatile uint32_t mlkem_runtime_mode;
static inline int mlkem_runtime_montgomery(void) { return mlkem_runtime_mode != 0; }
static inline int mlkem_runtime_barrett(void) { return mlkem_runtime_mode != 0; }
static inline int mlkem_runtime_keccak(void) {
#ifdef MLK_RUNTIME_SELECTED
  return mlkem_runtime_mode != 0;
#else
  return mlkem_runtime_mode == 2;
#endif
}
#endif
#endif
