# Roadmap

Status as of 2026-10-14. ✅ done · 🔶 in progress · ⬜ open

## Overview

| Phase | Goal | Status |
|---|---|---|
| P0 | Toolchain | ✅ |
| P1 | ROM verification | ✅ |
| P2 | Symbols of the PAL build | 🔶 functions done, data open |
| P3 | Recompiler configs | ✅ |
| P4 | Runtime fork: PAL timing, Controller Pak | 🔶 saving untested |
| P5 | Project skeleton and first boot | 🔶 save, restart and load untested |
| P6 | Stabilisation up to v0.1 | ⬜ |
| P7 | Graphics: widescreen, high frame rates | ⬜ |
| P8 | Mod SDK | ⬜ |
| P9 | Bundled mods | ⬜ |
| P10 | German and French releases | ⬜ |
| P11 | Reusable pipeline for more games | 🔶 |

## Next steps

1. Save at the inn in Melrode, restart and load the save (P4/P5).
2. Replace the launcher's "NTSC-U version" message for wrong dumps with one
   that names the European release (P1/P6).
3. Compare the game speed and audio pitch at 50 Hz with an emulator (P6).

## Phases

### P0: Toolchain ✅

- LLVM 19.1.3 with the MIPS target, MSVC 14.44 and Windows SDK 10.0.22621,
  CMake 3.31, Ninja and GNU make.
- N64Recomp, RSPRecomp and RecompModTool are built from the runtime's
  N64Recomp submodule.

### P1: ROM verification ✅

- recomp-toolkit's `rom-info` identifies dumps by hash, header and CIC, and
  recognises the known bad dump "(E) [b1]".
- The launcher accepts only the good dump.

Open:

- For a wrong dump with the right internal name, the launcher shows
  RecompFrontend's built-in message, which asks for the NTSC-U version.

### P2: Symbols of the PAL build 🔶

- ✅ 897 functions in the main segment and the three overlays, ported from the
  US symbols and checked against libultra signatures and call targets (see
  [TECHNICAL.md](TECHNICAL.md)).
- ⬜ Data symbols.
  - Port the US data names (player data, flags, battle state).
  - Confirm the gameplay variables with an emulator's RAM watch.

### P3: Recompiler configs ✅

- `hmc.en.toml` with the overlay hooks and two libleo stubs.
- `aspMain.en.toml` for the audio microcode.
- `patches.en.toml` for the patches.

### P4: Runtime fork 🔶

- ✅ Configurable VI rate: 50 Hz for PAL.
- ✅ `osViSetXScale` and `osViSetYScale`.
- ✅ Controller Pak emulated at the block level, saved as a 32 KiB `.mpk` image.
- ⬜ Verify a save written by the game.
- ⬜ Check that `.mpk` files from emulators can be imported and exported.

### P5: Project skeleton and first boot 🔶

- ✅ The game boots to the title screen. A new game plays through the opening
  scene with sound, keyboard input and the full-height PAL picture.
- ✅ The launcher works.
- ⬜ Title, new game, first town, save, restart, load.
- ⬜ Test controller input.

### P6: Stabilisation up to v0.1 ⬜

- A full playthrough including the ending overlay, without "Failed to find
  function" errors.
- Compare game speed and audio pitch at 50 Hz with an emulator.
- Long play sessions; check audio drift.
- Optional: CI builds with GitHub Actions.
- First release.

### P7: Graphics ⬜

- Widescreen and ultrawide.
  - Fix the stretched full-screen 2D backgrounds of the "Expand" aspect ratio.
  - Align the HUD with rt64's extended GBI.
- High frame rates through rt64's frame interpolation.
  - Group the matrices of the player, enemies and camera.
  - Skip interpolation on camera cuts.
  - rt64 assumes 60 Hz when it estimates the game's frame rate, which needs a
    change for 50 Hz games.
- Texture packs.
- An option between the original 50 Hz and 60 Hz.

### P8: Mod SDK ⬜

- A mod template repository with the headers, `mod.toml` for `hmc_en`, and the
  decomp as a submodule.
- An exported API.
  - Events: map loaded, battle start and end, level-up, every frame.
  - Getters and setters for player values and the encounter rate.
- Documentation and an example mod.

### P9: Bundled mods ⬜

Built with the public SDK and switchable in the mod menu:

- encounter rate,
- battle speed,
- text speed,
- experience display,
- a fix for the camera direction after battles,
- a free camera on the right stick.

### P10: German and French releases ⬜

- Port the symbols from the English build to the German one (NETD). A first
  comparison found 772 of 777 functions identical; the rest depends on the
  language.
- Build each release as its own variant (`HMC_VARIANT`, mod game id `hmc_de`).
- French after German.

### P11: Reusable pipeline 🔶

- ✅ recomp-toolkit has the ROM checks, symbol porting, build comparison and a
  game session script for tests.
- ⬜ Publish recomp-toolkit.
- ⬜ A project template and a "new game" playbook.
