//-----------------------------------------------------------------------------
// MurmurHash3 was written by Austin Appleby, and is placed in the public
// domain. The author hereby disclaims copyright to this source code.

#ifndef MurmurHash3_h
#define MurmurHash3_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
void MurmurHash3_x64_128(const void * key, int len, uint32_t seed, void * out);
#ifdef __cplusplus
}
#endif

#endif /* MurmurHash3_h */
