#!/usr/bin/env bash
# Build just the module package (not the whole firmware) with verbose output,
# tee everything into logs/build-<run id>.log so the failure is reproducible.
set -euo pipefail

SRC="${OPENWRT_SRC:-/build/openwrt}"
LOGS="${LOGS:-/build/logs}"
RUN_ID="${RUN_ID:-$(date -u +%Y-%m-%dT%H-%M-%SZ)}"
JOBS="${JOBS:-$(nproc)}"
LOG="${LOGS}/build-${RUN_ID}.log"

cd "$SRC"
echo "make -j${JOBS} package/kernel/mt7981b-ppe/compile V=s" | tee -a "$LOG"

set -o pipefail
make -j"$JOBS" package/kernel/mt7981b-ppe/compile V=s 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}

echo "---- summary ----" | tee -a "$LOG"
if [ "$rc" -ne 0 ]; then
    echo "build exit code: $rc" | tee -a "$LOG"
    grep -E 'undefined!|Error [0-9]|unknown symbol' "$LOG" | tail -20 | tee -a "$LOG"
fi
exit "$rc"
