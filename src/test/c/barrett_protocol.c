#include <stdint.h>
#include "sim.h"

static void puts_(const char *s) { while (*s) sim_putc(*s++); }

/* Volatile here ensures each test actually issues an instruction. Production
 * hooks are pure arithmetic and intentionally allow normal optimization. */
static intptr_t barrett_(uintptr_t a, uintptr_t noise) {
  intptr_t result;
  __asm__ volatile(".insn r 0x0b, 0, 3, %0, %1, %2"
                   : "=r"(result) : "r"(a), "r"(noise));
  return result;
}

static int32_t centered(int32_t a) {
  int32_t r = a % 3329;
  if (r > 1664) r -= 3329;
  if (r < -1664) r += 3329;
  return r;
}

static int32_t mont_ref(int32_t a) {
  int32_t t = (int16_t)((uint32_t)a * 62209u);
  return (a - t * 3329) >> 16;
}

static intptr_t montmul_(intptr_t a, intptr_t b) {
  intptr_t r;
  __asm__ volatile(".insn r 0x0b, 0, 1, %0, %1, %2"
                   : "=r"(r) : "r"(a), "r"(b));
  return r;
}

static intptr_t montred_(intptr_t a) {
  intptr_t r;
  __asm__ volatile(".insn r 0x0b, 0, 2, %0, %1, x0"
                   : "=r"(r) : "r"(a));
  return r;
}

int main(void) {
  uint32_t checksum = 0, expected_checksum = 0;
  for (uint32_t bits = 0; bits < 65536u; bits++) {
    int32_t a = (int16_t)bits;
    uintptr_t high = ((uintptr_t)0xa5a5a5a5u << 16);
    uintptr_t input = high | bits;
    intptr_t result = barrett_(input, ~input);
    int32_t expected = centered(a);
    if (result != (intptr_t)expected) return 1;
    checksum += (uint32_t)(result * 3 + 7);
    expected_checksum += (uint32_t)(expected * 3 + 7);
  }
  if (checksum != expected_checksum) return 2;

  /* RAW dependencies through Barrett, Montgomery multiply and Montgomery
   * reduction exercise the distinct custom-0 decoder entries together. */
  intptr_t value = -10000;
  int32_t expected = -10000;
  for (unsigned i = 0; i < 128; i++) {
    value = barrett_((uintptr_t)value, i);
    expected = centered((int16_t)expected);
    value = montmul_(value, 1353);
    expected = mont_ref(expected * 1353);
    value = montred_(value * 32768);
    expected = mont_ref(expected * 32768);
    if (value != (intptr_t)expected) return 3;
  }
  __asm__ volatile(".insn r 0x0b, 0, 3, x0, %0, x0" : : "r"((intptr_t)-1665));
  if (barrett_(0, ~(uintptr_t)0) != 0) return 4;
  puts_("Barrett ISA PASS: 65536 inputs, sign extension, high bits, RS2, dependencies, Montgomery, x0\n");
  return 0;
}
