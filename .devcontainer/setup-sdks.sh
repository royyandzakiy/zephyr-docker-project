#!/usr/bin/env bash
set -e

# --- 1. Check & Fetch Vanilla Zephyr (v4.2.2) ---
ZEPHYR_VAN_VER="v4.2.2"
ZEPHYR_BASE="/workdir/zephyr-sdks/$ZEPHYR_VAN_VER/zephyr"

if [ ! -d "$ZEPHYR_BASE" ]; then
    echo "=== Fetching Vanilla Zephyr $ZEPHYR_VAN_VER ==="
    mkdir -p "/workdir/zephyr-sdks/$ZEPHYR_VAN_VER"
    git clone --depth 1 --branch "$ZEPHYR_VAN_VER" https://github.com/zephyrproject-rtos/zephyr.git "$ZEPHYR_BASE"
    (cd "$ZEPHYR_BASE/.." && west init -l "$ZEPHYR_BASE" && west update --narrow -o=--depth=1)
else
    echo "=== Vanilla Zephyr $ZEPHYR_VAN_VER is ready ==="
fi

# --- 2. Check & Fetch nRF Connect SDK (v3.3.0) via ncs.py ---
NCS_VER="v3.3.0"
echo "=== Checking nRF Connect SDK $NCS_VER ==="
/usr/bin/python3 /workspaces/${localWorkspaceFolderBasename}/.devcontainer/ncs.py install "$NCS_VER"