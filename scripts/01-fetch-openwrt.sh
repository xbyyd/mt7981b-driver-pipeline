#!/usr/bin/env bash
# Clone the pinned OpenWrt tree and pull the feeds. Skipped on re-runs.
set -euo pipefail

SRC="${OPENWRT_SRC:-/build/openwrt}"
BRANCH="${OPENWRT_BRANCH:-openwrt-24.10}"

if [ -d "$SRC/.git" ]; then
    echo "tree already present at $SRC ($(git -C "$SRC" rev-parse --short HEAD))"
else
    echo "cloning ${BRANCH} ..."
    git clone --depth 1 --branch "$BRANCH" https://github.com/openwrt/openwrt.git "$SRC"
fi

cd "$SRC"
./scripts/feeds update -a
./scripts/feeds install -a

echo "feeds ready: $(git rev-parse --short HEAD) $(date -u +%FT%TZ)"
