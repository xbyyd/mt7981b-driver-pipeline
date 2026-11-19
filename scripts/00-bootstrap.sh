#!/usr/bin/env bash
# Sanity checks inside the image: toolchain pieces the OpenWrt build silently
# depends on (gcc-multilib for host tools, python3 for the build system).
set -euo pipefail

fail=0
for bin in gcc g++ make perl python3 rsync git patch xxd; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "MISSING: $bin"
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "bootstrap incomplete, aborting" >&2
    exit 1
fi

echo "host tools ok: $(gcc --version | head -1)"
echo "python         : $(python3 --version)"
echo "disk free      : $(df -h /build | awk 'NR==2 {print $4}')"
