# How Holy Magic Century: Recompiled works

This document explains how the port is put together, what is special about the
European (PAL) build, and why things were done the way they were. Building is
covered in [BUILDING.md](../BUILDING.md), the plan in [ROADMAP.md](ROADMAP.md).

## Pipeline

```
ROM ── N64Recomp hmc.en.toml (+ HolyMagicCenturyRecompSyms/) ──► RecompiledFuncs/   game code as C
ROM ── RSPRecomp aspMain.en.toml ──────────────────────────────► rsp/aspMain.cpp    audio microcode as C++
patches/*.c ── clang -target mips, ld.lld ──► patches.elf ── N64Recomp patches.en.toml ──► RecompiledPatches/, patches.bin

all of the above + N64ModernRuntime (fork) + rt64 + RecompFrontend ──► HolyMagicCenturyRecompiled.exe
```

At run time, N64ModernRuntime stands in for libultra (threads, messages, video
interrupts, audio, saves), rt64 renders the game's display lists, and
RecompFrontend provides the launcher, menus and input. The game still reads its
data from the ROM, so the launcher stores a copy of it the first time.

## The ROM

| | |
|---|---|
| Release | Holy Magic Century (Europe), English, serial NETP |
| Format | 16 MiB, CIC-6102, entry point 0x80000400 |
| Good dump | No-Intro; MD5 `80CC112F62E9A8581A1BB6A1D1E1488B`, SHA1 `139607EBA03326FBE9D899663C56E64042D51E84` |
| Code | libultra 2.0I, IDO 5.3, F3DEX 1.23 graphics microcode |

A widely shared file labelled "Holy Magic Century (E) [!]" (MD5
`FA6A2E00BBFF236DAC91F08544AFFA40`) is a known bad dump, listed as "[b1]" in
mupen64plus's ROM database. The game entry in `src/main/main.cpp` checks the
XXH3 hash of the good dump (`0x19b554e4afaeca41`), so the launcher refuses any
other file. For a file with the right internal name but another hash, such as
the bad dump, the launcher shows RecompFrontend's built-in message. That message
asks for the "NTSC-U" version, which is wrong for this project.

The German (NETD) and French releases are separate ROMs with one language each.

## Function symbols

N64Recomp needs the start and size of every function, and the names matter.
N64Recomp handles libultra functions by name (`src/symbol_lists.cpp` in
N64Recomp):

- *reimplemented* functions such as `osCreateThread` or `osViSetMode` are not
  recompiled; calls go to N64ModernRuntime's versions,
- *ignored* functions such as the VI manager thread are left out,
- *renamed* functions such as `sqrtf` are recompiled under another name so
  they don't clash with the C library,
- every other function is recompiled as it is.

A libultra function under the wrong name is recompiled although the runtime
must replace it, or the other way round. Either breaks the link or the game.

There is no decompilation of the PAL build. The symbols were ported from the US
function list of [Rainchus/Quest64Syms](https://github.com/Rainchus/Quest64Syms)
(816 functions in the main segment, 65 in the overlays) by
`tools/syms/build_syms.ps1`, using recomp-toolkit, this project's helper tools,
which are not published yet:

1. **libultra signatures.** `ram_image` writes the main segment as a RAM image,
   and [n64sym](https://github.com/shygoo/n64sym) finds libultra functions in it
   by signature. This gives their canonical names.
2. **Port.** `port_funcs` aligns the US function boundaries with the boundaries
   visible in the PAL code (returns, padding, call targets). It uses a Viterbi
   pass that keeps the address shift piecewise constant. 781 of the 816 US
   functions in the main segment have the same size in the PAL build.
3. **Refine.** The PAL build links parts of libultra in another order and
   contains functions the US build lacks, for example `osViSetYScale`. So
   `refine_funcs` rebuilds the function list from these sources:
   - the signatures,
   - every `jal` target,
   - stack-frame prologues right after `jr $ra`,
   - the ported starts.

   Where two names compete for one address, the name that N64Recomp handles
   specially wins.
4. **Manual decisions.** `tools/syms/overrides.en.toml` records them, each with
   its reason.

The result, `HolyMagicCenturyRecompSyms/hmc.en.syms.toml`, lists 897 functions:

| Section | VRAM | Functions |
|---|---|---|
| `.entry` | 0x80000400 | 1 |
| `.main` | 0x80000450 | 831: 268 named by libultra signatures, 559 by the port, 4 by overrides |
| `.ovl_title` | 0x80100000 | 8 |
| `.ovl_intro` | 0x80100000 | 34 |
| `.ovl_ending` | 0x80100000 | 23 |

The overrides settle four cases where neither n64sym nor the US list had the
right name. The code itself decided each one:

| Address | Name | Evidence |
|---|---|---|
| 0x8003D400 | `osMapTLBRdb` | contains `tlbwi`; Quest64Syms calls it `__createSpeedParam` |
| 0x80034AB0 | `viMgrMain` | static thread function of libultra's VI manager |
| 0x8003D034 | `send_mesg` | static helper of the exception handler, called 17 times from `__osException` |
| 0x80047AE0 | `osDestroyThread` | dispatches without yielding; Quest64Syms calls it `osStopThread` |

Sixteen more conflicts between n64sym and the US names were settled
automatically. One example is 0x80035050: n64sym says `guFrustumF`, but the
function calls `sinf` and `cosf`, so it is `guPositionF`. The build writes each
decision to `tools/syms/out/refine.en.txt`.

## Data symbols

`HolyMagicCenturyRecompSyms/hmc.en.datasyms.toml` names the game's data for
patches and mods. Examples:

- `gPlayerMainData`: the player's stats,
- `gCurrentMap`,
- `gBattleState`,
- `gInventory`.

recomp-toolkit's `port_data` ported them from the US data symbols of
Quest64Syms. It is the last step of `tools/syms/build_syms.ps1`.

There is no US ROM to compare code with. However, splat defines a data symbol
at every address the US code references and at every pointer in the US data.
The tool finds the same two kinds of references in the PAL build:

- `lui` + `addiu`/load/store pairs in the code,
- pointers in the data.

It then aligns both sets of addresses with a piecewise-constant shift that
keeps the data in order.

In the main segment:

- **Confirmed:** 1506 of the 1534 US symbols. The PAL build references the
  moved address.
- **Estimates:** 28.
- **PAL only:** 159 more addresses that only the PAL build references.

The shift is:

- +0x350 or +0x340 in the data,
- +0x7B0 from the libultra data on,
- +0x7A0 in the BSS.

The BSS has two stretches of +0x7A8, where the PAL build has 8 more bytes. One
of them begins right at `gPlayerMainData`, which sits at 0x8007C228.

Two checks back this up:

- **Decomp usage.** Each named symbol that one of the decomp's C functions uses
  is referenced by the same function in the PAL build (66 of 66). For
  `gPlayerMainData`, the PAL code's accesses fit the decomp's struct layout
  field by field, down to the byte-sized elements and levels.
- **n64sym.** Its libultra data symbols agree in 24 of 26 cases. The other two
  are wrong matches by n64sym: one lies past the end of the BSS, and the other
  contradicts its own confirmed neighbours.

Auto-named symbols (`D_…`) that stay unconfirmed are left out. Named ones keep
their estimated address and are listed in the report
(`tools/syms/out/data.en.txt`). Two of them, battle messages, were checked by
hand: the game's text encoding at the estimated addresses reads "Brian escape
from battle…" and "Brian won the battle!".

The title and intro overlays port well: 50 of 51 and 120 of 124 symbols are
confirmed. The ending overlay differs from the US one, so only its confirmed
symbols are written.

A test patch that reads `gPlayerMainData.currHP` compiled to a load from
0x8007C22C, the verified address plus the field offset.

## Overlays

The title, intro and ending code are overlays that share VRAM 0x80100000:

| Overlay | ROM | Size |
|---|---|---|
| title | 0xDA7090 | 0x1B8A0 |
| intro | 0xDC2930 | 0x65970 |
| ending | 0xE282A0 | 0x4DA30 |

Their bounds come from the ROM start/end table the game builds at 0x80031C58.
The game loads overlays with `func_80024690` and `dma_write`. The hooks in
`hmc.en.toml` call the runtime's `load_overlays(rom, vram, size)` there, so
calls into 0x80100000 reach the overlay that is loaded. This follows
Quest64-Recomp.

## Audio and graphics microcode

The audio microcode (aspMain) is recompiled by RSPRecomp:

- its text sits at ROM 0x4C340 (VRAM 0x8004B740) and is 0xE20 bytes long,
- it runs at IMEM 0x04001080,
- it is the same size as the US microcode, and its 16 indirect jump targets
  come from Quest64-Recomp.

`src/main/main.cpp` hands audio tasks (`M_AUDTASK`) to it. Graphics tasks go to
rt64, which supports the game's F3DEX 1.23 microcode.

## PAL specifics

- **TV type.** At 0x80000464 the boot code stores 0 (`OS_TV_PAL`) to `osTvType`
  at 0x80000300. The game then picks its PAL video mode by itself.
- **50 Hz.** Game logic and audio are paced by vertical interrupts (VIs), 50 per
  second on PAL. The runtime hard-coded 60 Hz, so the fork adds
  `ultramodern::set_vi_rate()` and `get_vi_rate()`, and `hmc_on_init` in
  `main.cpp` sets 50 before the game starts. The audio code in `main.cpp`
  derives its per-VI buffer size from the same rate. Nobody has compared the
  game speed with an emulator yet.
- **Picture height.**
  - The game draws a 240-line framebuffer and calls `osViSetYScale(0.833)` to
    stretch it over the 285-line PAL picture.
  - The runtime's `osViSetXScale` and `osViSetYScale` were stubs. Without the
    factor, rt64 estimated a 288-line framebuffer and drew the picture squashed
    into the top with a black band below.
  - The fork applies the factor to the VI scale register like libultra does.
- **rt64's frame rate estimate.** rt64 still assumes 60 Hz VIs: it computes a
  game's logical frame rate as 60 divided by the VIs per frame
  (`src/hle/rt64_vi.cpp`, "TODO: PAL support"). For a 50 Hz game the estimate is
  20 % too high, which matters for frame interpolation.

## Saving: the Controller Pak

The game has no EEPROM or SRAM; it saves to a Controller Pak. As in the
original, you can only save at inns and a few other places. The first is the
inn in Melrode (`gSaveLocation_MELRODE_INN` in the decomp).

Upstream N64ModernRuntime only stubs the pak functions: `osPfsInitPak` reports
that no pak is plugged in, and N64Recomp sends the game's `osPfs*` calls to these
stubs by name. There were two ways to get real saves:

1. Reimplement libultra's pak file system in the runtime. This is the approach
   of the open N64ModernRuntime pull request #139.
2. Keep the game's own pak code and emulate only the pak's 32-byte block reads
   and writes underneath.

This port does the second. It is less code, and the file system (pack IDs, inode
table, note directory) behaves exactly as on hardware, because it *is* the
game's code.

- `[keep_game_copy]` in `tools/syms/overrides.en.toml` renames the game's pak
  functions (`osPfsInitPak` becomes `osPfsInitPak_game` and so on). N64Recomp
  then recompiles them instead of using the runtime stubs. The game calls them
  by address, so its calls reach the copies.
- `librecomp/src/pak.cpp` in the fork implements what sits under them:
  - `__osContRamRead` and `__osContRamWrite` move 32-byte blocks,
  - `__osPfsGetStatus` and `osPfsIsPlug` report the pak,
  - `__osPfsSelectBank` handles the one bank of a standard pak,
  - `__osSiGetAccess` and `__osSiRelAccess` do nothing. The game's versions wait
    on a queue that only libultra's `osContInit` creates, and the runtime
    replaces `osContInit`.
- As in libultra, a write to the pack ID blocks is dropped unless it is forced.
- Only controller 1 has a pak.

The save file is `saves/holy_magic_century_eu_en.bin` in the config folder:
`run/` when it contains `portable.txt`. It is the 32 KiB pak in the raw layout
emulators use for `.mpk` files.

- A new pak starts formatted and empty, laid out like mupen64plus-core's
  `format_mempak`, with a random serial.
- The runtime writes the file through a temporary file and keeps the previous
  version as `holy_magic_century_eu_en.bin.bak`.

Status: reading works. On a fresh pak, LOAD on the title screen reports "No Holy
Magic saves found". Saving at an inn is not tested yet.

## Patches

`patches/` holds C code that changes the game:

1. It is compiled for MIPS with the decomp's headers (libultra 2.0H, F3DEX GBI)
   and rt64's extended GBI.
2. It is linked against the game's symbols (`patches.ld`, `syms.ld`).
3. N64Recomp recompiles it (`patches.en.toml`, strict patch mode).
4. The build embeds the result in the executable.

Fixes such as widescreen HUD placement will go here. So far the patches only
export `hmc_api_version()` for mods. RecompFrontend's mod API includes
`patches/ui_funcs.h` and `patches/recompui_event_structs.h`, so those two
headers have to stay where they are.

## Testing

Each change is checked in the running game. A script starts the game, sends
simulated key presses and takes screenshots: recomp-toolkit's
`scripts/game_session.ps1` keeps one game process running between steps. It
only sends keys while the game window is verifiably in front, so that no key
press lands in another program.

```powershell
game_session.ps1 start -Exe out\build\workspace-release\HolyMagicCenturyRecompiled.exe -WorkDir run -GameArgs '--game','hmc_en'
game_session.ps1 step -Keys enter -Wait 3 -Name title   # Start on the title screen, then a screenshot
game_session.ps1 hold -Keys w -HoldMs 1500 -Name walk    # walk forward
game_session.ps1 stop
```

## Decisions

- **Own project, not a fork of
  [Quest64-Recomp](https://github.com/Rainchus/Quest64-Recomp).**
  - That project targets the US release.
  - Its build is broken because two of its submodules were deleted.
  - It predates the current runtime and RecompFrontend.

  This port follows its overlay hooks and microcode setup.
- **Runtime changes live in a fork** (branch `hmc` of
  [lunixxx37/N64ModernRuntime](https://github.com/lunixxx37/N64ModernRuntime)).
  The upstream projects don't accept AI-generated contributions, so no pull
  requests go there.
- **English first.** The German and French builds follow once the English one
  is stable. They share almost all of their code with it, so most of the work
  carries over.

## Pitfalls met during bring-up

- **Font family.** RecompFrontend's primary font must be registered under the
  family name stored in the font file, "Inter Variable". Registered as "Inter",
  the launcher showed no text at all.
- **Header moves.** After headers move, stale `patches/*.d` files make `make`
  fail with "No rule to make target". Delete the patch build files.
- **Toolchain.** See [BUILDING.md](../BUILDING.md).
