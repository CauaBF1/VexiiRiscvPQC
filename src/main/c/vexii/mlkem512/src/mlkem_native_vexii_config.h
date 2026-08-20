#ifndef MLKEM_NATIVE_VEXII_CONFIG_H
#define MLKEM_NATIVE_VEXII_CONFIG_H

#include <stddef.h>
#include <stdint.h>

#define MLK_CONFIG_PARAMETER_SET 512
#define MLK_CONFIG_NAMESPACE_PREFIX mlkem
#define MLK_CONFIG_INTERNAL_API_QUALIFIER static
#define MLK_CONFIG_NO_ASM
#define MLK_CONFIG_CUSTOM_ZEROIZE

/* Per-component profiling hooks (inert unless -DMLK_PROFILE). Pulled in here so
 * the macros reach the whole amalgamated mlkem_native.c TU. */
#include "mlk_profile.h"

static inline void mlk_zeroize(void *ptr, size_t len) {
  volatile uint8_t *p = (volatile uint8_t *)ptr;

  while (len-- != 0) {
    *p++ = 0;
  }
}

#endif
