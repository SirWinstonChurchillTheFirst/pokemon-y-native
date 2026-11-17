# Builds a native Windows version of Pokémon Y from YOUR OWN dump of the game.
#
#   powershell -ExecutionPolicy Bypass -File setup-windows.ps1 -Rom "D:\dumps\game.3ds"
#
# Needs: git, CMake 3.25+ and MSYS2 (https://www.msys2.org) with the CLANG64 packages
#   pacman -S --needed mingw-w64-clang-x86_64-clang mingw-w64-clang-x86_64-lld mingw-w64-clang-x86_64-ninja mingw-w64-clang-x86_64-shaderc mingw-w64-clang-x86_64-vulkan-headers mingw-w64-clang-x86_64-vulkan-loader
# and a graphics card with Vulkan 1.1 or later. The dump has to be decrypted (.3ds, .cci or .cxi).
# Nothing of the game is downloaded or uploaded; everything made from it stays in the build folder.
param(
    [Parameter(Mandatory = $true)][string]$Rom,
    [string]$Out = "",
    [string]$Msys = "C:\msys64"
)
$ErrorActionPreference = "Stop"
if (-not $Out) { $Out = Join-Path $PSScriptRoot "build" }
$TitleId = "0004000000055E00"
$Runtime = "https://github.com/ShiromiyaG/Bergamota.git"
$Commit = "21007338e0655b675ab116273e602ff7d37e28e6"

function Stop-With($text) { Write-Host "stop: $text" -ForegroundColor Red; exit 1 }
function Run($what) {
    & $what[0] $what[1..($what.Length - 1)]
    if ($LASTEXITCODE -ne 0) { Stop-With "$($what[0]) failed ($LASTEXITCODE)" }
}

if (-not (Test-Path -LiteralPath $Rom)) { Stop-With "the game file is not there: $Rom" }
$Rom = (Resolve-Path -LiteralPath $Rom).Path
$bin = Join-Path $Msys "clang64\bin"
foreach ($tool in "clang.exe", "clang++.exe", "ninja.exe", "glslc.exe") {
    if (-not (Test-Path (Join-Path $bin $tool))) { Stop-With "$tool is missing in $bin (see the pacman line at the top of this script)" }
}
foreach ($tool in "git", "cmake") {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { Stop-With "$tool is not on the PATH" }
}
$env:PATH = "$bin;$env:PATH"
$env:CC = "clang"
$env:AR = "llvm-ar"
New-Item -ItemType Directory -Force $Out | Out-Null
$Out = (Resolve-Path -LiteralPath $Out).Path

# 1. the runtime, at the commit this was tested with, plus the local changes
$src = Join-Path $Out "runtime"
if (-not (Test-Path (Join-Path $src ".git"))) {
    Run @("git", "-c", "core.autocrlf=false", "clone", $Runtime, $src)
    Run @("git", "-C", $src, "checkout", "--quiet", $Commit)
    Run @("git", "-C", $src, "apply", "--whitespace=nowarn", (Join-Path $PSScriptRoot "bergamota-local.patch"))
}
$prefix = (Join-Path $Msys "clang64") -replace "\\", "/"
Run @("cmake", "-S", $src, "-B", (Join-Path $src "build"), "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release",
      "-DCMAKE_C_COMPILER=clang", "-DCMAKE_CXX_COMPILER=clang++", "-DCMAKE_PREFIX_PATH=$prefix")
Run @("cmake", "--build", (Join-Path $src "build"), "--target", "player", "3dsrecomp")

# 2. the game's own code, translated to C and compiled (a few minutes, all cores)
$lib = Join-Path $Out "lib"
Run @((Join-Path $src "build\3dsrecomp.exe"), "build", $Rom, $lib)
$dll = Join-Path $lib "$TitleId.dll"
if (-not (Test-Path $dll)) { Stop-With "no $TitleId.dll came out: is this dump Pokémon Y (title id $TitleId), and decrypted?" }

# 3. a folder to play from
$play = Join-Path $Out "play"
New-Item -ItemType Directory -Force (Join-Path $play "user") | Out-Null
Copy-Item (Join-Path $src "build\player.exe") $play -Force
Copy-Item $dll $play -Force
foreach ($name in "libc++.dll", "libunwind.dll") { Copy-Item (Join-Path $bin $name) $play -Force }
$config = Join-Path $play "player.toml"
if (-not (Test-Path $config)) {
    $q = { param($p) ($p -replace "\\", "/") }
    @"
[game]
game = '$(& $q $Rom)'
library = '$(& $q (Join-Path $play "$TitleId.dll"))'
user = '$(& $q (Join-Path $play "user"))'
update = ''

[video]
between = true
fullscreen = true
layout = 'side'
resolution = '1920x1080'
vsync = true
"@ | Set-Content -Encoding utf8 $config
}
"@echo off`r`ncd /d `"%~dp0`"`r`nstart `"`" `"%~dp0player.exe`" --config `"%~dp0player.toml`"`r`n" | Set-Content -Encoding ascii -NoNewline (Join-Path $play "Play.bat")
Write-Host "done: start $play\Play.bat (F1 = settings, F11 = fullscreen). Saves are in $play\user."
