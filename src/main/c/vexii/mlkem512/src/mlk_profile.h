/* Per-component cycle profiling for ML-KEM (indexed buckets).
 *
 * All inert unless -DMLK_PROFILE is set: the macros expand to nothing, so the
 * normal build is byte-identical. Included from mlkem_native_vexii_config.h so
 * the macros are visible across the whole amalgamated mlkem_native.c TU, where
 * the primitives are static and otherwise un-hookable. The mlk_prof_* arrays
 * are defined in main.c; the SCU accumulates, main.c snapshots/resets/prints.
 *
 * Nesting rule: only bracket functions that do NOT internally call another
 * bracketed one (e.g. rej_uniform_x4 squeezes Keccak, so we bracket the
 * keccak-free leaf mlk_rej_uniform_c instead). Overlap would double-count.
 */
#ifndef MLK_PROFILE_H
#define MLK_PROFILE_H

#ifdef MLK_PROFILE
#include <stdint.h>
enum {
  MLK_PB_KECCAK = 0, /* keccak-f1600 permutation                         */
  MLK_PB_NTT,        /* ntt + invntt + basemul + mulcache                */
  MLK_PB_SAMPLE,     /* rejection sampling (matrix gen), keccak-free leaf */
  MLK_PB_CBD,        /* centered binomial noise sampling                 */
  MLK_PB_COMPRESS,   /* compress/decompress (ciphertext/pk rounding)     */
  MLK_PB_ENCODE,     /* (de)serialize: tobytes/frombytes, from/tomsg     */
  MLK_PB_HASHBYTES,  /* SHAKE absorb/squeeze byte plumbing (xor/extract) */
  MLK_PB_N
};
extern uint64_t mlk_prof_cy[MLK_PB_N];
extern uint32_t mlk_prof_n[MLK_PB_N];
static inline uint64_t mlk_prof_rd(void) {
  uint64_t v;
  __asm__ volatile("rdcycle %0" : "=r"(v));
  return v;
}
#define MLK_PROF_ENTER()  uint64_t _pf0 = mlk_prof_rd()
#define MLK_PROF_EXIT(b)  do { mlk_prof_cy[(b)] += mlk_prof_rd() - _pf0; mlk_prof_n[(b)]++; } while (0)
#else
#define MLK_PROF_ENTER()
#define MLK_PROF_EXIT(b)
#endif

#endif /* MLK_PROFILE_H */
