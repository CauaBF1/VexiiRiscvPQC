#ifndef VEXII_SIM_H
#define VEXII_SIM_H

#include <stdint.h>

/* VexiiRiscv PeripheralEmulator, base 0x10000000 (see
 * src/main/scala/vexiiriscv/test/PeripheralEmulator.scala). */
#define SIM_BASE 0x10000000UL
#define SIM_PUTC (*(volatile uint8_t *)(SIM_BASE + 0x00))

static inline void sim_putc(char c) { SIM_PUTC = (uint8_t)c; }

#endif
