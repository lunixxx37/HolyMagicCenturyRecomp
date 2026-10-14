# Building Holy Magic Century: Recompiled

You need your own copy of **Holy Magic Century (Europe)** for the N64
(No-Intro SHA1 `139607EBA03326FBE9D899663C56E64042D51E84`). The build turns the
ROM's code into C; nothing derived from the ROM is part of this repository.

## 1. Clone

```sh
git clone --recurse-submodules https://github.com/lunixxx37/HolyMagicCenturyRecomp
```

`lib/` holds the submodules:

- `N64ModernRuntime`: a fork (branch `hmc`) with a configurable VI rate (50 Hz
  for PAL games) and block-level Controller Pak emulation,
- `rt64` and `RecompFrontend`,
- `quest64-decomp`: headers for the patches only.

`RecompFrontend` has to stay at `lib/RecompFrontend`: it includes
`../../../../../patches/ui_funcs.h` from this project.

## 2. Tools (Windows)

- Visual Studio 2022 Build Tools with "Desktop development with C++"
  (MSVC and the Windows SDK). The project builds with `clang-cl`.
- LLVM with the **MIPS** target for the patches. The `LLVM-*-win64.exe`
  installer lacks it; use the portable `LLVM-19.1.3-Windows-X64.tar.xz` release
  (not 19.1.0, whose MIPS backend is broken). Its `clang-cl` also works as the
  host compiler. Don't let CMake pick up its `llvm-mt.exe`, which is built
  without libxml2; the Windows SDK's `mt.exe` works.
- CMake 3.20 to 3.31 (CMake 4 rejects some dependency scripts), Ninja, GNU make.
- `N64Recomp` and `RSPRecomp` on `PATH`, built from `lib/N64ModernRuntime/N64Recomp`.
- Windows SDKs older than 10.0.26100 lack D3D12 additions that rt64 uses. Point
  `HMC_DIRECTX_HEADERS_DIR` at a checkout of
  [DirectX-Headers](https://github.com/microsoft/DirectX-Headers) in that case.

## 3. Generate the C code

Put the ROM in the repository root as `hmc.en.z64` in big-endian byte order.
Any N64 byte-order converter turns `.n64` and `.v64` files into that form; the
author uses `rom-info --to-z64` from recomp-toolkit, which is not published yet.
Then run:

```sh
N64Recomp hmc.en.toml
RSPRecomp aspMain.en.toml
```

This writes `RecompiledFuncs/` and `rsp/aspMain.cpp`.

## 4. Build

```sh
cmake --preset workspace-release
cmake --build --preset workspace-release
```

The `workspace-*` presets are the only presets so far:

- They keep a console window open for logs (`HMC_CONSOLE`).
- They take the DirectX-Headers checkout from
  `$RECOMP_WORKSPACE/_deps/DirectX-Headers`, the layout of the author's
  workspace. `RECOMP_WORKSPACE` is set by its devshell.
  - Without that variable the path leads nowhere. That is harmless with a
    Windows SDK of 10.0.26100 or newer.
  - With an older SDK, pass `-DHMC_DIRECTX_HEADERS_DIR=<checkout>` to the
    configure step.

The patches in `patches/` are compiled for MIPS, recompiled and embedded as part
of the build.

## 5. Run

Assets are loaded relative to the working directory. Double-click
`Start Holy Magic Century.cmd` (or use `run.ps1`) to start the build from
`run\`, which needs:

- an empty `portable.txt`, which keeps config, saves and the ROM copy in `run\`,
- `assets` (a copy or a junction to `..\assets`) and `recompcontrollerdb.txt`.

`.\run.ps1` opens the launcher, where you pick the ROM the first time.
`.\run.ps1 -Direct` starts the game right away once a ROM is stored.

The save file `run\saves\holy_magic_century_eu_en.bin` is the 32 KiB
Controller Pak in the raw `.mpk` layout emulators use.

## Symbols

`HolyMagicCenturyRecompSyms/` holds the function symbols of this build.
`tools/syms/build_syms.ps1` regenerates them from the US symbols of
[Rainchus/Quest64Syms](https://github.com/Rainchus/Quest64Syms) with
recomp-toolkit: it ports the US function list, checks it against n64sym's
libultra signatures and the game's call targets, and applies the manual
decisions in `tools/syms/overrides.*.toml`, each with its reason.
