#!/usr/bin/env bash
# Stage the out-of-tree kernel package into the tree and apply the hooks patch.
set -euo pipefail

SRC="${OPENWRT_SRC:-/build/openwrt}"
PKG=kernel/mt7981b-ppe
DEST="$SRC/package/$PKG"

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -r /build/package/kernel/mt7981b-ppe "$DEST"

cd "$SRC"
for p in /build/patches/*.patch; do
    [ -e "$p" ] || continue
    echo "applying $(basename "$p")"
    git apply --whitespace=nowarn "$p"
done

echo "staged package at package/$PKG"
