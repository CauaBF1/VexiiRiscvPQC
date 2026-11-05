#ifndef MLKEM_ACCEL_RUNTIME_H
#define MLKEM_ACCEL_RUNTIME_H
#include <stdint.h>
/* Same image: 0 C, 1 Montgomery, 2 Montgomery + Keccak. */
#ifdef MLK_RUNTIME_ACCEL
extern volatile uint32_t mlkem_runtime_mode;
#endif
#endif
