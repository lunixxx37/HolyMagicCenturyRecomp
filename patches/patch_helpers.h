#ifndef __PATCH_HELPERS_H__
#define __PATCH_HELPERS_H__

// Declares a host function once for both sides: the MIPS patches see a normal C
// prototype, the host build sees the recompiled calling convention.

#ifdef MIPS
#include "ultra64.h"
#else
#include "recomp.h"
#endif

#ifdef __cplusplus
#   define EXTERNC extern "C"
#else
#   define EXTERNC
#endif

#ifdef MIPS
#    define DECLARE_FUNC(type, name, ...) \
        EXTERNC type name(__VA_ARGS__)
#else // MIPS
#    define DECLARE_FUNC(type, name, ...) \
        EXTERNC void name(uint8_t* rdram, recomp_context* ctx)
#endif

#endif
