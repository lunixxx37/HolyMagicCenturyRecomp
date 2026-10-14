// Host stand-ins for libultra functions that N64Recomp skips (its ignored_funcs list) but that
// recompiled game code still calls. Each one is added when the linker reports it missing.

#include "recomp.h"
#include "ultramodern/ultramodern.hpp"

// Debug monitor output from leftover debug code in the game. Ignored for now.
extern "C" void rmonPrintf_recomp(uint8_t* rdram, recomp_context* ctx) {
}
