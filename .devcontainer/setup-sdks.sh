#!/usr/bin/env bash
set -e

# --- 1. Check & Fetch Vanilla Zephyr (v4.2.2) ---
ZEPHYR_VAN_VER="v4.2.2"
ZEPHYR_SDK_VER="0.17.0"
ZEPHYR_BASE="/workdir/zephyr-sdks/$ZEPHYR_VAN_VER/zephyr"
ZEPHYR_SDK_DIR="/workdir/zephyr-sdks/toolchains/zephyr-sdk-$ZEPHYR_SDK_VER"

# Download Zephyr SDK Toolchain if missing
if [ ! -d "$ZEPHYR_SDK_DIR" ]; then
    echo "=== Installing Zephyr SDK $ZEPHYR_SDK_VER ==="
    mkdir -p /workdir/zephyr-sdks/toolchains
    wget -qO- "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VER}/zephyr-sdk-${ZEPHYR_SDK_VER}_linux-x86_64_minimal.tar.xz" | tar -xJ -C /workdir/zephyr-sdks/toolchains
    (cd "$ZEPHYR_SDK_DIR" && ./setup.sh -h -t x86_64-zephyr-elf -t arm-zephyr-eabi)
fi

# Clone Vanilla Zephyr if missing
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
SCRIPT_PATH=$(find /workspaces -name "ncs.py" 2>/dev/null | head -n 1)

if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
    echo "=== Checking nRF Connect SDK $NCS_VER ==="
    /usr/bin/python3 "$SCRIPT_PATH" install "$NCS_VER"
else
    echo "Error: Could not locate ncs.py inside /workspaces" >&2
    exit 1
fi