# Zephyr & NCS

## Cloning latest Zephyr Vanilla

```bash
export ZEPHYR_VAN_VER="v4.2.2"
export ZEPHYR_BASE="/workdir/zephyr-sdks/$ZEPHYR_VAN_VER/zephyr"

git clone --depth 1 --branch $ZEPHYR_VAN_VER https://github.com/zephyrproject-rtos/zephyr.git "$ZEPHYR_BASE"
west init -l "$ZEPHYR_BASE"
west update --narrow -o=--depth=1
```

## Setting up Zephyr Vanilla path

### Short version

```bash
export ZEPHYR_VAN_VER="v4.2.2"
export ZEPHYR_BASE="/workdir/zephyr-sdks/$ZEPHYR_VAN_VER/zephyr"
source "$ZEPHYR_BASE/zephyr-env.sh"
```

### Complete Script

```bash
# 1. Define base path
export ZEPHYR_VAN_VER="v4.2.2"
export ZEPHYR_BASE="/workdir/zephyr-sdks/$ZEPHYR_VAN_VER/zephyr"

# 2. Validate repository path exists
if [ ! -d "$ZEPHYR_BASE" ]; then
    echo "Error: ZEPHYR_BASE path does not exist: $ZEPHYR_BASE" >&2
    return 1 2>/dev/null || exit 1
fi

# 3. Safely initialize West workspace if not already initialized
if [ ! -d "$ZEPHYR_BASE/../.west" ]; then
    (cd "$ZEPHYR_BASE/.." && west init -l "$ZEPHYR_BASE") || {
        echo "Error: Failed to initialize west workspace at $ZEPHYR_BASE" >&2
        return 1 2>/dev/null || exit 1
    }
fi

# 4. Source zephyr-env.sh safely
if [ -f "$ZEPHYR_BASE/zephyr-env.sh" ]; then
    source "$ZEPHYR_BASE/zephyr-env.sh"
else
    echo "Error: zephyr-env.sh not found inside $ZEPHYR_BASE" >&2
    return 1 2>/dev/null || exit 1
fi

echo "Successfully initialized Vanilla Zephyr environment at $ZEPHYR_BASE"
```

### Permanently adding it to `.bashrc`

```bash
export ZEPHYR_BASE="/workdir/zephyr-sdks/v4.2.2/zephyr"
if [ -f "$ZEPHYR_BASE/zephyr-env.sh" ]; then
    source "$ZEPHYR_BASE/zephyr-env.sh" > /dev/null
fi
```

---

## Prereq: Install nrfutil

```bash
# 1. Install base dependencies (including jq for ncs environment script)
sudo apt update && sudo apt install -y curl wget unzip jq python3-pip

# 2. Install nrfutil globally
curl -fSL "https://developer.nordicsemi.com/.pc-tools/nrfutil/x64-linux/nrfutil" -o /usr/local/bin/nrfutil
chmod +x /usr/local/bin/nrfutil

# 3. Install required nRF Util plugins
nrfutil install toolchain-manager
nrfutil install device

# 4. Install Nordic Command Line Tools (nrfjprog, mergehex, SEGGER J-Link)
NCLT_BASE="https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x"
NCLT_VER="10-24-0/nrf-command-line-tools-10.24.0"
NCLT_TMP=$(mktemp -d)

cd "${NCLT_TMP}"
wget -qO - "${NCLT_BASE}/${NCLT_VER}_linux-amd64.tar.gz" | tar --no-same-owner -xz
sudo mkdir -p /opt/SEGGER
sudo tar xzf JLink_*.tgz -C /opt/SEGGER
sudo mv /opt/SEGGER/JLink* /opt/SEGGER/JLink
sudo cp -r ./nrf-command-line-tools /opt
sudo ln -sf /opt/nrf-command-line-tools/bin/nrfjprog /usr/local/bin/nrfjprog
sudo ln -sf /opt/nrf-command-line-tools/bin/mergehex /usr/local/bin/mergehex
cd / && rm -rf "${NCLT_TMP}"
```

## Cloning latest nRF Connect SDK

### Short version

```bash
export NCS_VER="v3.3.0"
export NCS_DIR="/workdir/ncs-sdks/$NCS_VER"

# 1. Install toolchain using nrfutil
nrfutil toolchain-manager install --ncs-version $NCS_VER --install-dir /workdir/ncs-sdks/toolchains

# 2. Fetch NCS sources via west
mkdir -p "$NCS_DIR" && cd "$NCS_DIR"
west init -m https://github.com/nrfconnect/sdk-nrf --mr $NCS_VER .
west update --narrow -o=--depth=1
```

### Complete version

```bash
export NCS_VER="v3.3.0"
export NCS_BASE_DIR="/workdir/ncs-sdks"
export NCS_TARGET_DIR="$NCS_BASE_DIR/$NCS_VER"
export NCS_TOOLCHAINS_DIR="$NCS_BASE_DIR/toolchains"

# 1. Ensure target directories exist
mkdir -p "$NCS_TARGET_DIR" "$NCS_TOOLCHAINS_DIR"

# 2. Install toolchain via nrfutil if not already installed
echo "Checking nRF Connect Toolchain for $NCS_VER..."
nrfutil toolchain-manager install --ncs-version "$NCS_VER" --dir "$NCS_TOOLCHAINS_DIR" || {
    echo "Error: Failed to install toolchain for $NCS_VER via nrfutil" >&2
    return 1 2>/dev/null || exit 1
}

# 3. Fetch NCS manifest and submodules via West
if [ ! -d "$NCS_TARGET_DIR/zephyr" ]; then
    echo "Fetching nRF Connect SDK sources ($NCS_VER)..."
    cd "$NCS_TARGET_DIR" || exit 1
    
    west init -m https://github.com/nrfconnect/sdk-nrf --mr "$NCS_VER" . || {
        echo "Error: Failed to initialize west manifest for $NCS_VER" >&2
        return 1 2>/dev/null || exit 1
    }
    
    west update --narrow -o=--depth=1 || {
        echo "Error: West update failed for $NCS_VER" >&2
        return 1 2>/dev/null || exit 1
    }
else
    echo "NCS sources for $NCS_VER already exist in $NCS_TARGET_DIR"
fi

echo "Successfully cloned nRF Connect SDK $NCS_VER"
```

## Setting up nRF Connect SDK path

```bash
# 1. Target NCS version to use
export NCS_VER="v3.3.0"
export NCS_BASE_DIR="/workdir/ncs-sdks"

# 2. Extract toolchain hash/bundle ID from toolchains.json
TOOLCHAINS_JSON="$NCS_BASE_DIR/toolchains/toolchains.json"

if [ -f "$TOOLCHAINS_JSON" ]; then
    NCS_HASH=$(jq -r --arg ver "$NCS_VER" '.[0].toolchains[] | select(.ncs_versions[] | contains($ver)) | .identifier.bundle_id' "$TOOLCHAINS_JSON")
fi

if [ -z "$NCS_HASH" ] || [ "$NCS_HASH" = "null" ]; then
    echo "Error: Could not locate toolchain bundle ID for $NCS_VER in $TOOLCHAINS_JSON" >&2
    return 1 2>/dev/null || exit 1
fi

NCS_TC_PATH="$NCS_BASE_DIR/toolchains/$NCS_HASH"

# 3. Export NCS and Zephyr base variables
export NCS_TOOLCHAIN_PATH="$NCS_TC_PATH"
export ZEPHYR_BASE="$NCS_BASE_DIR/$NCS_VER/zephyr"
export ZEPHYR_SDK_INSTALL_DIR="$NCS_TC_PATH/opt/zephyr-sdk"

# 4. Export library and binary paths
export LD_LIBRARY_PATH="$NCS_TC_PATH/usr/local/lib:$NCS_TC_PATH/opt/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$NCS_TC_PATH/usr/local/bin:$NCS_TC_PATH/opt/bin:$NCS_TC_PATH/bin:$PATH"

# 5. Initialize west workspace if needed, and source Zephyr environment
if [ ! -d "$ZEPHYR_BASE/../.west" ]; then
    (cd "$ZEPHYR_BASE/.." && west init -l "$ZEPHYR_BASE")
fi

if [ -f "$ZEPHYR_BASE/zephyr-env.sh" ]; then
    source "$ZEPHYR_BASE/zephyr-env.sh"
fi

echo "Switched to nRF Connect SDK $NCS_VER"
```