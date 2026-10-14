#include "patches.h"
#include "misc_funcs.h"
#include "graphics.h"

// Game patches go here. A function marked RECOMP_PATCH replaces the game function
// of the same name (see HolyMagicCenturyRecompSyms/hmc.en.syms.toml for the names).

// Version of the API the base recomp exports to mods. Mods can import it with
// RECOMP_IMPORT("*", u32 hmc_api_version(void)) to check for features.
RECOMP_EXPORT u32 hmc_api_version(void) {
    return 1;
}
