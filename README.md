# Pokémon Y, native

Scripts that build a native Windows or Linux program of **Pokémon Y** (Nintendo 3DS, title id
`0004000000055E00`) **from your own dump of the game**. The game's ARM code is translated to C ahead of
time (static recompilation) and runs on [Bergamota](https://github.com/ShiromiyaG/Bergamota), a small 3DS
system with a Vulkan renderer. No emulator is involved, and nothing of the game is in this repository.

> **Beta.** This was put together and tested in one evening (17 November 2026). It starts, plays into the
> game and saves; nobody has played it through. Expect problems, and keep your emulator.

The runtime's author plans a port of this game of their own, **Duality (X / Y)**. When it is out, use that: it will know the game, where this is only the plain game on the plain runtime.

## What was tested

New game in German from the language screen through the professor's talk, the name entry on the touch screen and the bedroom scene; walking around the room, the X menu, saving, and after a restart Continue from that save. Not tested: anything after the bedroom (no battle, no outdoor area), long sessions. Also on a low-budget machine (Batocera Linux mini PC, AMD Ryzen 3 PRO 4350GE, Radeon Vega 6): the same new-game route and the Continue route, started from the system's menu, with a photo of the screen checked for each; 60 shown / 30 game pictures a second once the shaders of a scene are cached. The first time a scene is shown its shaders are compiled, which drops the game to as low as 8 to 20 pictures a second for up to a minute (measured in Pokémon X's opening); the cache is kept.

Tested mainly on Windows 11 (Intel Core i7-13700KF, NVIDIA GeForce RTX 3070 Ti) with the player in a window and
fullscreen, picture by picture from scripted input (`test/`), and the Linux build the same way in WSL2
(Ubuntu 24.04, software Vulkan). The game's sound was recorded and checked to be music, not listened to.
A gamepad was not tested here; input was scripted.

## Speed

Measured in the player while walking in the first room, 15 seconds. The game itself makes 30 pictures
a second there, as on the console; the player draws one more between each two ("between = true"), so 60 are shown.

| Machine | Shown per second | The game's own | Idle |
|---|---|---|---|
| Windows 11, Intel Core i7-13700KF, NVIDIA GeForce RTX 3070 Ti | 60.3 | 30.1 | 95 % |
| Batocera Linux mini PC (HP), AMD Ryzen 3 PRO 4350GE with Radeon Vega 6 graphics, 8 GB | 60.1 | 30.1 | 91 % |

"Idle" is the share of each second the game's thread had nothing to do: the room for slower machines.

## Build it

You need your own **decrypted** dump (`.3ds`, `.cci` or `.cxi`). Dumps, keys and updates are not provided
here and never will be.

**Windows** (git, CMake, MSYS2 with the CLANG64 packages named at the top of the script, a Vulkan card):

```powershell
powershell -ExecutionPolicy Bypass -File setup-windows.ps1 -Rom "D:\dumps\game.3ds"
```

**Linux** (the packages named at the top of the script):

```sh
./setup-linux.sh /path/to/game.3ds
```

Either one clones Bergamota at commit `2100733`, applies `bergamota-local.patch`, builds the player and
the recompiler (about five minutes), translates and compiles the game (two to four minutes on a recent
desktop) and leaves a `build/play` folder with a start file. Saves are in `build/play/user`.

The scripts build the game as it is on the card (v1.0), without an update.

## Playing

F1 opens the player's settings (resolution, layout of the two screens, controls), F11 switches fullscreen.
A gamepad is picked up by SDL; the keyboard works too (arrow keys, X = A, Z = B, S = X, A = Y, Q/W = L/R,
Return = Start, I/J/K/L = circle pad). The bottom screen takes the mouse.

## What is in here

| File | What it is |
|---|---|
| `setup-windows.ps1`, `setup-linux.sh` | the build, start to finish |
| `bergamota-local.patch` | changes to the runtime: it builds with MSYS2's clang, a "side" layout for the two screens, Vulkan pipeline libraries and a shader warm-up against stutter on slow GPUs, a lock around the memory guards (a crash), and switches for testing (scripted input, a sound dump) |
| `test/` | the scripted input the test above was played with, and the tool that turns it into a recording |
| `game.json` | this game's data |

## Credits

- **Bergamota**, the runtime, the recompiler's C++ and the player: ShiromiyaG, MIT.
  https://github.com/ShiromiyaG/Bergamota
- **3dsrecomp** and **Zakuro**, which Bergamota's recompiler and parts of its system are translated from: fearkov, MIT.
  https://github.com/fearkov/3dsrecomp, https://github.com/fearkov/zakuro
- The work here (the scripts, the patch, the testing) was done with Claude (Anthropic).

Not affiliated with Nintendo, Game Freak, Creatures or The Pokémon Company. Pokémon and Nintendo 3DS are
trademarks of their owners. You need to own the game.
