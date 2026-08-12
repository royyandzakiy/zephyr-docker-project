FROM zephyrprojectrtos/zephyr-build:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# ----------- SETTING UP NRF CONNECT TOOLS

# 1. Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget unzip jq python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install nrfutil & plugins
RUN curl -fSL "https://developer.nordicsemi.com/.pc-tools/nrfutil/x64-linux/nrfutil" -o /usr/local/bin/nrfutil \
    && chmod +x /usr/local/bin/nrfutil \
    && nrfutil install toolchain-manager \
    && nrfutil install device

# 3. Install Nordic Command Line Tools (nrfjprog, mergehex, J-Link)
ARG NORDIC_COMMAND_LINE_TOOLS_VERSION="10-24-0/nrf-command-line-tools-10.24.0"
RUN NCLT_BASE=https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x && \
    NCLT_TMP=$(mktemp -d) && cd "${NCLT_TMP}" && \
    wget -qO - "${NCLT_BASE}/${NORDIC_COMMAND_LINE_TOOLS_VERSION}_linux-amd64.tar.gz" | tar --no-same-owner -xz && \
    mkdir -p /opt/SEGGER && tar xzf JLink_*.tgz -C /opt/SEGGER && mv /opt/SEGGER/JLink* /opt/SEGGER/JLink && \
    cp -r ./nrf-command-line-tools /opt && \
    ln -s /opt/nrf-command-line-tools/bin/nrfjprog /usr/local/bin/nrfjprog && \
    ln -s /opt/nrf-command-line-tools/bin/mergehex /usr/local/bin/mergehex && \
    ln -s /opt/SEGGER/JLink/JLinkExe /usr/local/bin/JLinkExe && \
    echo "/opt/SEGGER/JLink" > /etc/ld.so.conf.d/SEGGER_JLink.conf && ldconfig && \
    cd / && rm -rf "${NCLT_TMP}"

# ----------- SETTING UP USE/RESET ZEPHYR ENVIRONMENT

# Example Usage:
#   use-ncs v3.3.0     # Switches PATH and env vars to nRF Connect SDK v3.3.0
#   reset-ncs          # Restores clean baseline environment
#   use-vanilla v4.2.2 # Switches to Vanilla Zephyr v4.2.2

# Append SDK environment helpers to bashrc
RUN cat << 'EOF' >> /root/.bashrc

if [ -z "$_ORIG_PATH" ]; then
    export _ORIG_PATH="$PATH"
    export _ORIG_LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
fi

use-ncs() {
    local target_ver="${1:-v3.3.0}"
    local script_path
    
    # 1. Clear out any prior Vanilla or NCS environment overrides
    reset-ncs > /dev/null

    script_path=$(find /workspaces -name "ncs.py" 2>/dev/null | head -n 1)

    if [ -n "$script_path" ] && [ -f "$script_path" ]; then
        eval "$(/usr/bin/python3 "$script_path" "$target_ver")"
    else
        echo "Error: Could not locate ncs.py script." >&2
        return 1
    fi
}

use-vanilla() {
    local target_ver="${1:-v4.2.2}"
    
    # 1. Clear out any prior NCS or Zephyr environment overrides
    reset-ncs > /dev/null
    
    # 2. Export Vanilla Zephyr paths
    export ZEPHYR_BASE="/workdir/zephyr-sdks/${target_ver}/zephyr"
    
    if [ -f "$ZEPHYR_BASE/zephyr-env.sh" ]; then
        source "$ZEPHYR_BASE/zephyr-env.sh"
        echo "Switched to Vanilla Zephyr ${target_ver}"
    else
        echo "Error: Vanilla Zephyr not found at $ZEPHYR_BASE" >&2
        return 1
    fi
}

reset-ncs() {
    export PATH="$_ORIG_PATH"
    if [ -n "$_ORIG_LD_LIBRARY_PATH" ]; then
        export LD_LIBRARY_PATH="$_ORIG_LD_LIBRARY_PATH"
    else
        unset LD_LIBRARY_PATH
    fi
    unset ZEPHYR_BASE ZEPHYR_SDK_INSTALL_DIR NCS_TOOLCHAIN_PATH ZEPHYR_TOOLCHAIN_VARIANT
    echo "Reset environment to container baseline."
}
EOF