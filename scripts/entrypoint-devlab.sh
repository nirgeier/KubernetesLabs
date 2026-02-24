#!/usr/bin/env bash
# =============================================================================
# entrypoint-devlab.sh — Starts Docker daemon, waits for readiness, execs CMD
# =============================================================================
set -e

echo "==> Starting Docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &

echo "==> Waiting for Docker daemon..."
TRIES=0
MAX_TRIES=30
until docker info >/dev/null 2>&1; do
    TRIES=$((TRIES + 1))
    if [ "$TRIES" -ge "$MAX_TRIES" ]; then
        echo "ERROR: Docker daemon failed to start after ${MAX_TRIES}s"
        tail -20 /var/log/dockerd.log
        exit 1
    fi
    sleep 1
done
echo "==> Docker daemon is ready."

exec "$@"
