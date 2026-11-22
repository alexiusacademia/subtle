#!/usr/bin/env python3
# Puts one system's newest release into the release feed, keeping the
# other system's entry as it is. The feed is what the website's
# download buttons read.
#
#   tools/feed.py <feed.json> <macos|windows|linux|linux_arm64> <version> <url> <file> [notes url] [installer url] [installer file]
#
# <url> and <file> are what the app's updater fetches (on macOS the disk
# image, on Windows the zip). When the website hands out something else,
# it goes in beside them: on macOS the installer package as pkg,
# pkg_sha256 and pkg_size (the updater doesn't read them); on Windows the
# installer as setup, setup_sha256 and setup_size (copies the installer
# put in update with it); on Linux, where <url> is the AppImage, the .deb
# as deb, deb_sha256 and deb_size (copies the .deb put in update with it).
#
# Author: Alexius Academia
# Date: 2026-11-23 (from Draftwork's)
import hashlib, json, os, sys

feed_path, system, version, url, installer = sys.argv[1:6]
notes = sys.argv[6] if len(sys.argv) > 6 else ""
empty = {"version": "", "url": "", "sha256": "", "size": 0, "notes": ""}
feed = {"macos": dict(empty), "windows": dict(empty), "linux": dict(empty), "linux_arm64": dict(empty)}
if os.path.exists(feed_path):
    try:
        feed.update(json.load(open(feed_path)))
    except ValueError:
        pass
digest = hashlib.sha256(open(installer, "rb").read()).hexdigest()
feed[system] = {"version": version, "url": url, "sha256": digest,
                "size": os.path.getsize(installer), "notes": notes}
if len(sys.argv) > 8 and sys.argv[7]:
    key = {"windows": "setup", "linux": "deb", "linux_arm64": "deb"}.get(system, "pkg")
    feed[system][key] = sys.argv[7]
    feed[system][key + "_sha256"] = hashlib.sha256(open(sys.argv[8], "rb").read()).hexdigest()
    feed[system][key + "_size"] = os.path.getsize(sys.argv[8])
json.dump(feed, open(feed_path, "w"), indent=2)
open(feed_path, "a").write("\n")
print(f"{system}: {version}  {digest}")
