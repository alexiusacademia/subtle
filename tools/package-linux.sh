#!/bin/bash
# Makes Subtle for Linux on this Mac, for x86-64 and ARM64:
#   build/dist/Subtle-<version>-x86_64.AppImage   (and -aarch64) one file
#       that runs on most desktops (glibc 2.28 or newer): the website's
#       download, and what AppImage copies update with
#   build/dist/subtle_<version>_amd64.deb   (and _arm64) for Debian and
#       Ubuntu (and their kin), with Subtle in the menus: copies it put
#       in update with the next .deb
#
# They come from `tessel build --linux --bundle` and `--linux-arm --bundle`
# (the first build of a Tessel version downloads its Linux parts, once).
#
# Author: Alexius Academia
# Date: 2026-11-23
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
cd "$here"
tessel="${TESSEL:-$HOME/.tessel/bin/tessel}"
version="$(sed -n 's/^version = "\(.*\)"/\1/p' tessel.toml | head -1)"
out="build/dist"
mkdir -p "$out"

# build <tessel option> <AppImage arch> <deb arch> <ELF machine byte>
build() {
    local option="$1" arch="$2" debarch="$3" elf="$4"
    local image="$out/Subtle-$version-$arch.AppImage" deb="$out/subtle_${version}_$debarch.deb"
    echo "==> Subtle $version for Linux ($arch)"
    rm -rf build/linux-pkg
    mkdir -p build/linux-pkg
    "$tessel" build . "$option" --bundle -o build/linux-pkg/subtle | tail -2
    local made="build/linux-pkg/Subtle-$arch.AppImage"
    head -c 4 "$made" | tail -c 3 | grep -q ELF || { echo "error: the AppImage isn't a Linux program" >&2; exit 1; }
    [ "$(od -An -tx1 -j18 -N1 "$made" | tr -d ' \n')" = "$elf" ] || { echo "error: the AppImage isn't for $arch" >&2; exit 1; }
    mv "$made" "$image"
    chmod 755 "$image"
    mv "build/linux-pkg/subtle_${version}_$debarch.deb" "$deb"
    echo "→ $image ($(du -sh "$image" | cut -f1))"
    shasum -a 256 "$image"
    echo "→ $deb ($(du -sh "$deb" | cut -f1))"
    shasum -a 256 "$deb"
}

build --linux x86_64 amd64 3e
build --linux-arm aarch64 arm64 b7
