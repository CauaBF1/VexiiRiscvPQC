#ifndef VEXII_CYCLE_H
#define VEXII_CYCLE_H

#include <stdint.h>

/* Read the complete architectural counter on both RV32 and RV64. The
 * high/low/high sequence also handles a low-half rollover on RV32. */
static inline uint64_t vexii_read_cycle(void) {
#if __riscv_xlen == 32
  uint32_t hi, lo, again;
  do {
    __asm__ volatile("rdcycleh %0\nrdcycle %1\nrdcycleh %2"
                     : "=r"(hi), "=r"(lo), "=r"(again) : : "memory");
  } while (hi != again);
  return ((uint64_t)hi << 32) | lo;
#else
  uint64_t value;
  __asm__ volatile("rdcycle %0" : "=r"(value) : : "memory");
  return value;
#endif
}

#endif
