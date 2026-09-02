#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "mlkem_native.h"

/* glibc exports moncontrol(), but does not expose a public declaration. */
extern void moncontrol(int mode);

enum operation {
  OP_KEYPAIR,
  OP_ENCAPS,
  OP_DECAPS,
  OP_ALL,
};

struct options {
  enum operation operation;
  uint64_t iterations;
  uint64_t warmup;
};

static uint8_t pk[CRYPTO_PUBLICKEYBYTES];
static uint8_t sk[CRYPTO_SECRETKEYBYTES];
static uint8_t ct[CRYPTO_CIPHERTEXTBYTES];
static uint8_t ss_enc[CRYPTO_BYTES];
static uint8_t ss_dec[CRYPTO_BYTES];
static uint8_t keypair_coins[2 * CRYPTO_BYTES];
static uint8_t encaps_coins[CRYPTO_BYTES];

static const char *operation_name(enum operation operation) {
  switch (operation) {
    case OP_KEYPAIR:
      return "keypair";
    case OP_ENCAPS:
      return "encaps";
    case OP_DECAPS:
      return "decaps";
    case OP_ALL:
      return "all";
  }
  return "invalid";
}

static int parse_operation(const char *text, enum operation *operation) {
  if (strcmp(text, "keypair") == 0) {
    *operation = OP_KEYPAIR;
  } else if (strcmp(text, "encaps") == 0) {
    *operation = OP_ENCAPS;
  } else if (strcmp(text, "decaps") == 0) {
    *operation = OP_DECAPS;
  } else if (strcmp(text, "all") == 0) {
    *operation = OP_ALL;
  } else {
    return -1;
  }
  return 0;
}

static int parse_u64(const char *text, uint64_t *value) {
  char *end = NULL;
  unsigned long long parsed;

  errno = 0;
  parsed = strtoull(text, &end, 10);
  if (errno != 0 || end == text || *end != '\0') {
    return -1;
  }
  *value = (uint64_t)parsed;
  return 0;
}

static void usage(const char *program) {
  fprintf(stderr,
          "usage: %s --operation keypair|encaps|decaps|all "
          "--iterations N [--warmup N]\n",
          program);
}

static int parse_options(int argc, char **argv, struct options *options) {
  int have_operation = 0;
  int have_iterations = 0;

  options->operation = OP_ALL;
  options->iterations = 0;
  options->warmup = 50;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--operation") == 0 && i + 1 < argc) {
      if (parse_operation(argv[++i], &options->operation) != 0) {
        return -1;
      }
      have_operation = 1;
    } else if (strcmp(argv[i], "--iterations") == 0 && i + 1 < argc) {
      if (parse_u64(argv[++i], &options->iterations) != 0 ||
          options->iterations == 0) {
        return -1;
      }
      have_iterations = 1;
    } else if (strcmp(argv[i], "--warmup") == 0 && i + 1 < argc) {
      if (parse_u64(argv[++i], &options->warmup) != 0) {
        return -1;
      }
    } else {
      return -1;
    }
  }

  return have_operation && have_iterations ? 0 : -1;
}

static void initialize_inputs(void) {
  for (size_t i = 0; i < sizeof(keypair_coins); i++) {
    keypair_coins[i] = (uint8_t)(0x31u + (uint8_t)(17u * i));
  }
  for (size_t i = 0; i < sizeof(encaps_coins); i++) {
    encaps_coins[i] = (uint8_t)(0xA7u ^ (uint8_t)(29u * i));
  }
}

static int setup_keypair(void) {
  return crypto_kem_keypair_derand(pk, sk, keypair_coins);
}

static int setup_ciphertext(void) {
  int result = setup_keypair();
  result |= crypto_kem_enc_derand(ct, ss_enc, pk, encaps_coins);
  return result;
}

static int execute_once(enum operation operation) {
  int result = 0;

  switch (operation) {
    case OP_KEYPAIR:
      result = crypto_kem_keypair_derand(pk, sk, keypair_coins);
      break;
    case OP_ENCAPS:
      result = crypto_kem_enc_derand(ct, ss_enc, pk, encaps_coins);
      break;
    case OP_DECAPS:
      result = crypto_kem_dec(ss_dec, ct, sk);
      break;
    case OP_ALL:
      result = crypto_kem_keypair_derand(pk, sk, keypair_coins);
      result |= crypto_kem_enc_derand(ct, ss_enc, pk, encaps_coins);
      result |= crypto_kem_dec(ss_dec, ct, sk);
      break;
  }
  return result;
}

static int prepare_operation(enum operation operation) {
  if (operation == OP_ENCAPS) {
    return setup_keypair();
  }
  if (operation == OP_DECAPS) {
    return setup_ciphertext();
  }
  return 0;
}

static int validate_operation(enum operation operation) {
  int result = 0;

  if (operation == OP_KEYPAIR) {
    result |= crypto_kem_enc_derand(ct, ss_enc, pk, encaps_coins);
    result |= crypto_kem_dec(ss_dec, ct, sk);
  } else if (operation == OP_ENCAPS) {
    result |= crypto_kem_dec(ss_dec, ct, sk);
  }

  if (operation == OP_KEYPAIR || operation == OP_ENCAPS || operation == OP_ALL ||
      operation == OP_DECAPS) {
    result |= memcmp(ss_enc, ss_dec, CRYPTO_BYTES) != 0;
  }
  return result;
}

static double elapsed_seconds(const struct timespec *start,
                              const struct timespec *end) {
  time_t seconds = end->tv_sec - start->tv_sec;
  long nanoseconds = end->tv_nsec - start->tv_nsec;
  return (double)seconds + (double)nanoseconds / 1000000000.0;
}

int main(int argc, char **argv) {
  struct options options;
  struct timespec start;
  struct timespec end;
  int result = 0;

  /* Exclude argument parsing, setup, warmup and correctness checks. */
  moncontrol(0);

  if (parse_options(argc, argv, &options) != 0) {
    usage(argv[0]);
    return 2;
  }

  initialize_inputs();
  result |= prepare_operation(options.operation);
  for (uint64_t i = 0; i < options.warmup; i++) {
    result |= execute_once(options.operation);
  }
  if (result != 0) {
    fprintf(stderr, "ERROR: setup/warmup failed\n");
    return 1;
  }

  if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) {
    perror("clock_gettime");
    return 1;
  }
  moncontrol(1);
  for (uint64_t i = 0; i < options.iterations; i++) {
    result |= execute_once(options.operation);
  }
  moncontrol(0);
  if (clock_gettime(CLOCK_MONOTONIC, &end) != 0) {
    perror("clock_gettime");
    return 1;
  }

  result |= validate_operation(options.operation);
  printf("PROFILE operation=%s iterations=%" PRIu64
         " warmup=%" PRIu64 " elapsed_seconds=%.9f status=%s\n",
         operation_name(options.operation), options.iterations, options.warmup,
         elapsed_seconds(&start, &end), result == 0 ? "PASS" : "FAIL");
  return result == 0 ? 0 : 1;
}
