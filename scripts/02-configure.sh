#!/usr/bin/env bash
# Write a minimal seed config, then let OpenWrt expand it.
# Deliberately does NOT enable CONFIG_NET_MEDIATEK_SOC_WED - that is the
# variable under investigation, see README "Root cause".
set -euo pipefail

SRC="${OPENWRT_SRC:-/build/openwrt}"
TARGET="${OPENWRT_TARGET:-mediatek}"
SUBTARGET="${OPENWRT_SUBTARGET:-filogic}"

cd "$SRC"

cat > .config <<'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_bananapi_bpi-r3-mini=y
CONFIG_DEVEL=y
CONFIG_TARGET_KERNEL_PARTSIZE=16
CONFIG_TARGET_ROOTFS_PARTSIZE=128
# module under test
CONFIG_PACKAGE_kmod-mt7981b-ppe=m
# keep the image lean; no WED glue on purpose (see README)
# CONFIG_NET_MEDIATEK_SOC_WED is not set
EOF

make defconfig

echo "generated .config, $(grep -c '^CONFIG_' .config) options"
echo "NET_MEDIATEK_SOC_WED: $(grep -c 'NET_MEDIATEK_SOC_WED=y' .config || true) (0 = off, expected here)"
