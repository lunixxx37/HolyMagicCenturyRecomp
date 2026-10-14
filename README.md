# Holy Magic Century: Recompiled

A native PC port of **Holy Magic Century**, the European release of Quest 64,
made by static recompilation with [N64Recomp](https://github.com/N64Recomp/N64Recomp),
[N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime),
[rt64](https://github.com/rt64/rt64) and
[RecompFrontend](https://github.com/N64Recomp/RecompFrontend).

**Status: early bring-up.** The game boots to its title screen, runs at the PAL
rate of 50 Hz and finds an emulated Controller Pak. Known issue: the PAL picture
sits too high and is stretched. Sound, controls and saving still need testing.
Planned: widescreen and high frame rates, quality-of-life and camera options,
and a mod SDK.

You need your own ROM of Holy Magic Century (Europe). This project contains no
game code or assets. It is not affiliated with the game's developer or
publishers, or with Nintendo.

## How it was made

- The function symbols were ported from the US decompilation work of
  [Rainchus/Quest64-Decomp](https://github.com/Rainchus/Quest64-Decomp) and
  [Rainchus/Quest64Syms](https://github.com/Rainchus/Quest64Syms) to the PAL
  build with recomp-toolkit, using n64sym signatures for libultra
  (`tools/syms/`).
- The overlay hooks and the audio microcode setup follow
  [Rainchus/Quest64-Recomp](https://github.com/Rainchus/Quest64-Recomp), the
  recompilation of the US release.
- The project structure is adapted from
  [HarvestMoon64Recomp](https://github.com/HarvestMoon64Recomp/HarvestMoon64Recomp).
- Large parts of this project were written with the help of an AI assistant
  (Claude). Changes to the N64Recomp libraries live in this project's own forks;
  the upstream projects do not accept AI-generated contributions.

## License

GPL-3.0, see [LICENSE](LICENSE).

Building: see [BUILDING.md](BUILDING.md).
