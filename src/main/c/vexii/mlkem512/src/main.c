#include <stdint.h>

#include "mlkem_native.h"
#include "sim.h"

#ifndef BENCH_ROUNDS
#define BENCH_ROUNDS 2u
#endif

static uint8_t pk[MLKEM512_PUBLICKEYBYTES];
static uint8_t sk[MLKEM512_SECRETKEYBYTES];
static uint8_t ct[MLKEM512_CIPHERTEXTBYTES];
static uint8_t ss1[MLKEM512_BYTES];
static uint8_t ss2[MLKEM512_BYTES];

static void print(const char *str) {
  while (*str) {
    sim_putc(*str++);
  }
}

static void println(const char *str) {
  print(str);
  sim_putc('\n');
}

static void print_hex64(uint64_t value) {
  for (int i = 15; i >= 0; i--) {
    uint32_t digit = (value >> (i * 4)) & 0xF;
    sim_putc(digit < 10 ? ('0' + digit) : ('A' + digit - 10));
  }
}

static void print_hex8(uint8_t value) {
  uint8_t hi = (value >> 4) & 0xF, lo = value & 0xF;
  sim_putc(hi < 10 ? ('0' + hi) : ('A' + hi - 10));
  sim_putc(lo < 10 ? ('0' + lo) : ('A' + lo - 10));
}

static void print_bytes_prefix(const char *label, const uint8_t *buf, uint32_t n) {
  print(label);
  print("=");
  for (uint32_t i = 0; i < n; i++) print_hex8(buf[i]);
  sim_putc('\n');
}

static inline uint64_t read_cycle(void) {
  uint64_t value;
  asm volatile("rdcycle %0" : "=r"(value)); /* rv64: full 64-bit counter */
  return value;
}

static int shared_secret_matches(void) {
  for (uint32_t i = 0; i < MLKEM512_BYTES; i++) {
    if (ss1[i] != ss2[i]) return 0;
  }
  return 1;
}

static void print_result(const char *label, int value) {
  print(label);
  print("=0x");
  print_hex64((uint64_t)(uint32_t)value);
  sim_putc('\n');
}

static void print_cycles(const char *label, uint64_t cycles) {
  print(label);
  print("=0x");
  print_hex64(cycles);
  sim_putc('\n');
}

#ifdef MLK_PROFILE
/* Definitions for the arrays declared extern in mlk_profile.h; the
 * mlkem_native.c TU adds into these, we snapshot/reset/print them per op. */
uint64_t mlk_prof_cy[MLK_PB_N];
uint32_t mlk_prof_n[MLK_PB_N];

static const char *const prof_names[MLK_PB_N] = {
  "keccak", "ntt", "sample", "cbd", "compress", "encode", "hashbytes"
};

static void prof_reset(void) {
  for (int i = 0; i < MLK_PB_N; i++) { mlk_prof_cy[i] = 0; mlk_prof_n[i] = 0; }
}

static void prof_snapshot(uint64_t *cy, uint32_t *n) {
  for (int i = 0; i < MLK_PB_N; i++) { cy[i] = mlk_prof_cy[i]; n[i] = mlk_prof_n[i]; }
}

static void prof_print(const char *op, const uint64_t *cy, const uint32_t *n) {
  for (int i = 0; i < MLK_PB_N; i++) {
    print(op); sim_putc('_'); print(prof_names[i]);
    print("_cy=0x"); print_hex64(cy[i]); sim_putc('\n');
    print(op); sim_putc('_'); print(prof_names[i]);
    print("_n=0x"); print_hex64(n[i]); sim_putc('\n');
  }
}
#endif

/* Returns 1 on full success for this round, 0 otherwise. */
static int run_round(uint32_t round) {
  print("round=");
  print_hex64(round);
  sim_putc('\n');

#ifdef MLK_PROFILE
  uint64_t kp_cy[MLK_PB_N], en_cy[MLK_PB_N], de_cy[MLK_PB_N];
  uint32_t kp_n[MLK_PB_N], en_n[MLK_PB_N], de_n[MLK_PB_N];
  prof_reset();
#endif
  uint64_t t0 = read_cycle();
  int keypair_ret = mlkem_keypair(pk, sk);
  uint64_t t1 = read_cycle();
#ifdef MLK_PROFILE
  prof_snapshot(kp_cy, kp_n); prof_reset();
#endif
  int enc_ret = mlkem_enc(ct, ss1, pk);
  uint64_t t2 = read_cycle();
#ifdef MLK_PROFILE
  prof_snapshot(en_cy, en_n); prof_reset();
#endif
  int dec_ret = mlkem_dec(ss2, ct, sk);
  uint64_t t3 = read_cycle();
#ifdef MLK_PROFILE
  prof_snapshot(de_cy, de_n);
#endif

  int ok = (keypair_ret == 0 && enc_ret == 0 && dec_ret == 0 && shared_secret_matches());

  print_result("keypair_ret", keypair_ret);
  print_result("enc_ret", enc_ret);
  print_result("dec_ret", dec_ret);
  print_result("ss_match", shared_secret_matches());

  print_bytes_prefix("pk_prefix", pk, 8);
  print_bytes_prefix("ct_prefix", ct, 8);
  print_bytes_prefix("ss1_prefix", ss1, 8);
  print_bytes_prefix("ss2_prefix", ss2, 8);

  print_cycles("cycles_keypair", t1 - t0);
  print_cycles("cycles_enc", t2 - t1);
  print_cycles("cycles_dec", t3 - t2);
#ifdef MLK_PROFILE
  prof_print("keypair", kp_cy, kp_n);
  prof_print("enc", en_cy, en_n);
  prof_print("dec", de_cy, de_n);
#endif
  return ok;
}

int main(void) {
  int all_ok = 1;

  println("VexiiRiscv ML-KEM-512 start");

  for (uint32_t round = 1; round <= BENCH_ROUNDS; round++) {
    all_ok &= run_round(round);
  }

  println("done");
  return all_ok ? 0 : 1; /* crt.S routes 0 -> pass symbol, non-zero -> fail */
}
