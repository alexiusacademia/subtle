#!/bin/bash
# Publishes Subtle: builds and uploads the macOS disk image, the Windows
# installer and the Linux AppImages and .debs (x86-64 and ARM64), writes the
# release feed, and deploys the website with the new download links.
#
#   tools/publish.sh                 build everything, upload, deploy the website
#   tools/publish.sh --skip-build    upload what's already in build/dist
#   tools/publish.sh --no-website    don't deploy the website
#   tools/publish.sh --website-only  deploy the website as it is, and nothing else
#   tools/publish.sh --dry-run       show what would be uploaded, without doing it
#
# The version is the one in tessel.toml: change it there first. Needs
# `gcloud` signed in, the bucket made once with tools/gcs-setup.sh, and
# Netlify signed in (npx netlify login).
#
# What ends up where (see packaging/publish.env):
#   gs://<bucket>/updates/<version>/Subtle-<version>.dmg
#   gs://<bucket>/updates/<version>/Subtle-<version>-setup.exe
#   gs://<bucket>/updates/<version>/Subtle-<version>-x86_64.AppImage, subtle_<version>_amd64.deb
#   gs://<bucket>/updates/<version>/Subtle-<version>-aarch64.AppImage, subtle_<version>_arm64.deb
#   gs://<bucket>/updates/latest.json   the feed: newest version, links and checksums per system
#   website/downloads.json              the same feed, for the download buttons
#
# Author: Alexius Academia
# Date: 2026-11-23 (after Draftwork's)
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source packaging/publish.env; set +a

build=1
website=1
release=1
dry=0
for arg in "$@"; do
    case "$arg" in
        --skip-build) build=0 ;;
        --no-website) website=0 ;;
        --website-only) release=0 ;;
        --dry-run) dry=1 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done
run() { if [ "$dry" = 1 ]; then echo "   (dry run) $*"; else "$@"; fi; }

version="$(sed -n 's/^version = "\(.*\)"/\1/p' tessel.toml | head -1)"
base="$SUBTLE_PUBLIC_BASE/updates/$version"
remote="gs://$SUBTLE_GCS_BUCKET/updates"
dist="build/dist"
dmg="$dist/Subtle-$version.dmg"
setup="$dist/Subtle-$version-setup.exe"
image="$dist/Subtle-$version-x86_64.AppImage"
deb="$dist/subtle_${version}_amd64.deb"
armImage="$dist/Subtle-$version-aarch64.AppImage"
armDeb="$dist/subtle_${version}_arm64.deb"

deploy() {
    [ -n "$SUBTLE_NETLIFY_SITE" ] || { echo "error: SUBTLE_NETLIFY_SITE isn't set in packaging/publish.env" >&2; exit 1; }
    echo "→ publishing the website"
    run npx -y netlify deploy --prod --dir website --site "$SUBTLE_NETLIFY_SITE" --message "$1"
}

if [ "$release" = 0 ]; then
    deploy "Subtle's website"
    echo "→ done: $SUBTLE_SITE_URL"
    exit 0
fi

echo "==> publishing Subtle $version"
if [ "$build" = 1 ]; then
    tools/package.sh
    tools/package-windows.sh
    tools/package-linux.sh
fi
for f in "$dmg" "$setup" "$image" "$deb" "$armImage" "$armDeb"; do
    [ -f "$f" ] || { echo "error: $f isn't there (run without --skip-build)" >&2; exit 1; }
done
xcrun stapler validate "$dmg" > /dev/null || { echo "error: $dmg isn't notarized" >&2; exit 1; }

echo "→ uploading"
for f in "$dmg" "$setup" "$image" "$deb" "$armImage" "$armDeb"; do
    run gcloud storage cp "$f" "$remote/$version/$(basename "$f")" --cache-control="public, max-age=31536000, immutable"
done

echo "→ updating the feed"
feed="$dist/latest.json"
curl -fsS "$SUBTLE_PUBLIC_BASE/updates/latest.json" -o "$feed" 2>/dev/null || rm -f "$feed"
python3 tools/feed.py "$feed" macos "$version" "$base/$(basename "$dmg")" "$dmg"
python3 tools/feed.py "$feed" windows "$version" "$base/$(basename "$setup")" "$setup"
python3 tools/feed.py "$feed" linux "$version" "$base/$(basename "$image")" "$image" "" "$base/$(basename "$deb")" "$deb"
python3 tools/feed.py "$feed" linux_arm64 "$version" "$base/$(basename "$armImage")" "$armImage" "" "$base/$(basename "$armDeb")" "$armDeb"
run gcloud storage cp "$feed" "$remote/latest.json" --cache-control="no-cache, max-age=0" --content-type="application/json"

if [ "$dry" = 0 ]; then
    echo "→ checking the downloads"
    for f in "$dmg" "$setup" "$image" "$deb" "$armImage" "$armDeb"; do
        u="$base/$(basename "$f")"
        got="$(curl -fsSL "$u" | shasum -a 256 | cut -d' ' -f1)"
        want="$(shasum -a 256 "$f" | cut -d' ' -f1)"
        [ "$got" = "$want" ] || { echo "error: what's online at $u isn't what was built" >&2; exit 1; }
    done
    for sys in macos windows linux linux_arm64; do
        online="$(curl -fsS "$SUBTLE_PUBLIC_BASE/updates/latest.json?t=$RANDOM" | python3 -c "import json,sys; print(json.load(sys.stdin)['$sys']['version'])")"
        [ "$online" = "$version" ] || { echo "error: the feed online says $sys $online, not $version" >&2; exit 1; }
    done
    cp "$feed" website/downloads.json
fi

if [ "$website" = 1 ]; then
    deploy "Subtle $version"
fi
echo "→ done: $SUBTLE_SITE_URL"
