#!/bin/bash
# Use available CPUs for the build and preserve resource evidence in Actions logs.
set -euo pipefail

mkdir -p ci-logs
cpu_count=$(nproc)
jobs=$cpu_count
interval=${RESOURCE_MONITOR_INTERVAL:-60}
if ! [[ "$interval" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid resource monitor interval" >&2
    exit 2
fi
monitor_pid=''

snapshot() {
    echo "[ci-resource] $(date -u '+%Y-%m-%dT%H:%M:%SZ') jobs=$jobs cpus=$cpu_count"
    free -m
    df -h .
    cat /proc/loadavg
    # Process names only: arguments may contain credentials.
    ps -eo pid,comm,rss,pcpu --sort=-rss | head -n 10 || true
}

monitor() {
    trap - EXIT
    local sleeper=''
    trap 'if [ -n "$sleeper" ]; then kill "$sleeper" 2>/dev/null || true; wait "$sleeper" 2>/dev/null || true; fi; exit 0' TERM INT
    while true; do
        sleep "$interval" &
        sleeper=$!
        wait "$sleeper" || break
        sleeper=''
        snapshot | tee -a ci-logs/resources.log
    done
}

cleanup() {
    if [ -n "$monitor_pid" ]; then
        kill "$monitor_pid" 2>/dev/null || true
        wait "$monitor_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT
snapshot | tee -a ci-logs/resources.log
monitor &
monitor_pid=$!

set +e
make -j"$jobs" 2>&1 | tee ci-logs/build.log
statuses=("${PIPESTATUS[@]}")
set -e
result=${statuses[0]}
if [ "$result" -eq 0 ] && [ "${statuses[1]}" -ne 0 ]; then
    result=${statuses[1]}
fi
# A signal/runner shutdown must not launch another build during cancellation.
if [ "$result" -gt 0 ] && [ "$result" -lt 128 ]; then
    echo "Parallel build failed ($result); retrying once with verbose single-job output."
    set +e
    make -j1 V=s 2>&1 | tee -a ci-logs/build.log
    statuses=("${PIPESTATUS[@]}")
    set -e
    result=${statuses[0]}
    if [ "$result" -eq 0 ] && [ "${statuses[1]}" -ne 0 ]; then
        result=${statuses[1]}
    fi
fi
snapshot | tee -a ci-logs/resources.log
exit "$result"
