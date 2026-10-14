# Holy Magic Century: Recompiled

A native PC port of **Holy Magic Century**, the European release of Quest 64,
made by static recompilation with [N64Recomp](https://github.com/N64Recomp/N64Recomp),
[N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime),
[rt64](https://github.com/rt64/rt64) and
[RecompFrontend](https://github.com/N64Recomp/RecompFrontend).

**Status: early bring-up.** A new game starts and plays with sound, keyboard
input and the full-height PAL picture at 50 Hz. The game reads its emulated
Controller Pak; saving at an inn and loading that save still need a test. A full
playthrough is still to come. See [the roadmap](docs/ROADMAP.md).

You need your own ROM of Holy Magic Century (Europe, English). This project
contains no game code or assets. It is not affiliated with the game's developer
or publishers, or with Nintendo.

## Playing

After building (see [BUILDING.md](BUILDING.md)), double-click
`Start Holy Magic Century.cmd`. The launcher offers **Start Game**, **Controls**,
**Settings** and **Mods**. A console window with the log opens as well; closing
it ends the game.

Default keyboard controls (change them under **Controls**; controllers get a
default layout too, but have not been tested yet):

| Key | N64 |
|---|---|
| Space | A |
| Left Shift | B |
| Enter | Start |
| W A S D | Control stick |
| Arrow keys | C buttons |
| I J K L | D-pad |
| E / R / Q | L / R / Z |

In game, **Esc** (Back/Select on a controller) opens the settings menu.

**Saving** works as in the original: only at inns and a few other places, the
first being the inn in Melrode. The game saves to its Controller Pak, which is
the file `run/saves/holy_magic_century_eu_en.bin`: a 32 KiB image in the raw
`.mpk` layout emulators use.

## Known issues

- Saving at an inn and loading that save are not verified yet.
- With the default "Expand" aspect ratio, full-screen 2D backgrounds such as
  the title screen are stretched. Set **Aspect Ratio** to **Original** in the
  graphics settings for 4:3 until the widescreen patches exist.
- If the launcher says your ROM is "the correct game, but the wrong version" and
  asks for the NTSC-U version, your file is not the verified European dump. The
  common "(E) [!]" file is a known bad dump. The message comes from
  RecompFrontend; this project needs the European release.
- rt64 assumes 60 Hz vertical interrupts when it estimates the game's frame
  rate; frame interpolation is not tuned for the 50 Hz PAL rate yet.
- Only Holy Magic Century (Europe, English) is supported. The German and
  French releases are planned.

## Documentation

- [BUILDING.md](BUILDING.md): building from source.
- [docs/TECHNICAL.md](docs/TECHNICAL.md): how the port works, what is special
  about the PAL build, and why things were done the way they were.
- [docs/ROADMAP.md](docs/ROADMAP.md): the plan and its status.

## How it was made

- The function symbols were ported from the US decompilation work of
  [Rainchus/Quest64-Decomp](https://github.com/Rainchus/Quest64-Decomp) and
  [Rainchus/Quest64Syms](https://github.com/Rainchus/Quest64Syms) to the PAL
  build with recomp-toolkit, this project's helper tools (not published yet),
  using n64sym signatures for libultra (`tools/syms/`).
- The overlay hooks and the audio microcode setup follow
  [Rainchus/Quest64-Recomp](https://github.com/Rainchus/Quest64-Recomp), the
  recompilation of the US release.
- The project structure is adapted from
  [HarvestMoon64Recomp](https://github.com/HarvestMoon64Recomp/HarvestMoon64Recomp).
- The runtime changes for PAL timing, the PAL picture and the Controller Pak
  live in the fork [lunixxx37/N64ModernRuntime](https://github.com/lunixxx37/N64ModernRuntime)
  (branch `hmc`).
- Large parts of this project were written with the help of an AI assistant
  (Claude). Changes to the N64Recomp libraries live in this project's own forks;
  the upstream projects do not accept AI-generated contributions.

## License

GPL-3.0, see [LICENSE](LICENSE).
