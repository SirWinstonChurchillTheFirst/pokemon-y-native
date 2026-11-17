#!/bin/bash
# Builds a native Linux version of Pokémon Y from YOUR OWN dump of the game.
#
#   ./setup-linux.sh /path/to/game.3ds [build folder]
#
# Needs (Ubuntu 24.04 names): git clang lld cmake ninja-build libvulkan-dev glslc
#   libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev libxfixes-dev libxtst-dev
#   libxkbcommon-dev libwayland-dev wayland-protocols libegl-dev libasound2-dev libpulse-dev libdrm-dev
#   libgbm-dev libudev-dev libdbus-1-dev libibus-1.0-dev
# and a graphics card with Vulkan 1.1 or later. The dump has to be decrypted (.3ds, .cci or .cxi).
# Nothing of the game is downloaded or uploaded; everything made from it stays in the build folder.
set -e
TITLE_ID=0004000000055E00
RUNTIME=https://github.com/ShiromiyaG/Bergamota.git
COMMIT=21007338e0655b675ab116273e602ff7d37e28e6
HERE=$(cd "$(dirname "$0")" && pwd)
ROM=$1
OUT=${2:-$HERE/build}
stop() { echo "stop: $*" >&2; exit 1; }
[ -f "$ROM" ] || stop "give the game file: ./setup-linux.sh /path/to/game.3ds"
ROM=$(realpath "$ROM")
for tool in git clang clang++ cmake ninja glslc; do command -v $tool >/dev/null || stop "$tool is missing (see the list at the top of this script)"; done
mkdir -p "$OUT"; OUT=$(realpath "$OUT")

# 1. the runtime, at the commit this was tested with, plus the local changes
SRC=$OUT/runtime
if [ ! -d "$SRC/.git" ]; then
  git clone "$RUNTIME" "$SRC"
  git -C "$SRC" checkout --quiet $COMMIT
  git -C "$SRC" apply --whitespace=nowarn "$HERE/bergamota-local.patch"
fi
# libstdc++ and libgcc linked in, so the player also starts on systems without them (Batocera)
cmake -S "$SRC" -B "$SRC/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++ -static-libgcc"
cmake --build "$SRC/build" --target player 3dsrecomp

# 2. the game's own code, translated to C and compiled (a few minutes, all cores)
CC=clang AR=llvm-ar "$SRC/build/3dsrecomp" build "$ROM" "$OUT/lib"
[ -f "$OUT/lib/$TITLE_ID.so" ] || stop "no $TITLE_ID.so came out: is this dump Pokémon Y (title id $TITLE_ID), and decrypted?"

# 3. a folder to play from
PLAY=$OUT/play
mkdir -p "$PLAY/user"
cp "$SRC/build/player" "$OUT/lib/$TITLE_ID.so" "$PLAY/"
if [ ! -f "$PLAY/player.toml" ]; then
  cat > "$PLAY/player.toml" <<EOF
[game]
game = '$ROM'
library = '$PLAY/$TITLE_ID.so'
user = '$PLAY/user'
update = ''

[video]
between = true
fullscreen = true
layout = 'side'
resolution = '1920x1080'
vsync = true
EOF
fi
printf '#!/bin/bash\ncd "$(dirname "$0")" && exec ./player --config player.toml\n' > "$PLAY/play.sh"
chmod +x "$PLAY/play.sh"
echo "done: start $PLAY/play.sh (F1 = settings, F11 = fullscreen). Saves are in $PLAY/user."
