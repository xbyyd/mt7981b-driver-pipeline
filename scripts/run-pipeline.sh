#!/usr/bin/env bash
# Entry point: run the whole porting pipeline inside the container.
# Every stage is idempotent; re-running picks up where the previous run stopped.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS="${LOGS:-/build/logs}"
RUN_ID="$(date -u +%Y-%m-%dT%H-%M-%SZ)"

mkdir -p "$LOGS"
export LOGS RUN_ID

echo "== mt7981b-driver-pipeline =="
echo "run id     : $RUN_ID"
echo "openwrt    : ${OPENWRT_BRANCH} / ${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}"
echo "source tree: ${OPENWRT_SRC}"
echo

for stage in 00-bootstrap 01-fetch-openwrt 02-configure 03-apply-patches 04-build; do
    echo "---- ${stage} ----"
    bash "$HERE/${stage}.sh" 2>&1 | tee -a "${LOGS}/pipeline-${RUN_ID}.log"
done

echo
echo "pipeline finished. build log: ${LOGS}/build-${RUN_ID}.log"
