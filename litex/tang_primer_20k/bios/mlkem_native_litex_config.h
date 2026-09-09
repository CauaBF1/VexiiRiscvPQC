#ifndef MLKEM_NATIVE_LITEX_CONFIG_H
#define MLKEM_NATIVE_LITEX_CONFIG_H

#include <stddef.h>
#include <stdint.h>

#include "mlkem_accel_select.h"

#define MLK_CONFIG_PARAMETER_SET 512
#define MLK_CONFIG_NAMESPACE_PREFIX mlkem
#define MLK_CONFIG_INTERNAL_API_QUALIFIER static
#if defined(MLK_USE_KECCAK)
#define MLK_CONFIG_USE_NATIVE_BACKEND_FIPS202
#define MLK_CONFIG_FIPS202_BACKEND_FILE "mlkem_keccak_vexii.h"
#else
#define MLK_CONFIG_NO_ASM
#endif
#define MLK_CONFIG_NO_RANDOMIZED_API
#define MLK_CONFIG_CUSTOM_ZEROIZE

static inline void mlk_zeroize(void *ptr, size_t len)
{
	volatile uint8_t *p = (volatile uint8_t *)ptr;
	while (len-- != 0)
		*p++ = 0;
}

#endif
