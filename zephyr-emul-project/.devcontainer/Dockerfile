FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

SHELL [ "/bin/bash", "-euxo", "pipefail", "-c" ]

# 1. Install base build tooling
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install \
        wget unzip clang-format clangd gcc-multilib make libffi8 \
        git curl python3-pip python3-venv cmake ninja-build libyaml-0-2 libffi7 && \
    pip3 install --no-cache-dir west && \
    apt-get -y clean && rm -rf /var/lib/apt/lists/*

# 2. Install nrfutil globally
ENV NRFUTIL_HOME=/usr/local/share/nrfutil
RUN wget -q https://developer.nordicsemi.com/.pc-tools/nrfutil/x64-linux/nrfutil && \
    mv nrfutil /usr/local/bin && chmod +x /usr/local/bin/nrfutil && \
    nrfutil install toolchain-manager

# 3. Install Nordic Command Line Tools (nrfjprog, mergehex, J-Link)
ARG NORDIC_COMMAND_LINE_TOOLS_VERSION="10-24-0/nrf-command-line-tools-10.24.0"
RUN NCLT_BASE=https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x && \
    NCLT_TMP=$(mktemp -d) && cd "${NCLT_TMP}" && \
    wget -qO - "${NCLT_BASE}/${NORDIC_COMMAND_LINE_TOOLS_VERSION}_linux-amd64.tar.gz" | tar --no-same-owner -xz && \
    mkdir -p /opt/SEGGER && tar xzf JLink_*.tgz -C /opt/SEGGER && mv /opt/SEGGER/JLink* /opt/SEGGER/JLink && \
    cp -r ./nrf-command-line-tools /opt && \
    ln -s /opt/nrf-command-line-tools/bin/nrfjprog /usr/local/bin/nrfjprog && \
    ln -s /opt/nrf-command-line-tools/bin/mergehex /usr/local/bin/mergehex && \
    cd / && rm -rf "${NCLT_TMP}"

# 4. Configure environment switching in .bashrc
RUN cat << 'EOF' >> /root/.bashrc

# Preserve clean baseline environment
if [ -z "$_ORIG_PATH" ]; then 
    export _ORIG_PATH="$PATH"
    export _ORIG_LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
fi

# Switch NCS version using system python explicitly
use-ncs() { 
    eval "$(LD_LIBRARY_PATH="" /usr/bin/python3 /workspaces/zephyr-emul-project/.devcontainer/ncs.py "$1")"
}

# Reset environment back to container baseline
reset-ncs() { 
    export PATH="$_ORIG_PATH"
    if [ -n "$_ORIG_LD_LIBRARY_PATH" ]; then 
        export LD_LIBRARY_PATH="$_ORIG_LD_LIBRARY_PATH"
    else 
        unset LD_LIBRARY_PATH
    fi
    unset ZEPHYR_BASE ZEPHYR_SDK_INSTALL_DIR NCS_TOOLCHAIN_PATH ZEPHYR_TOOLCHAIN_VARIANT
    echo "Reset environment to default."
}
EOF

# Ensure target mount path exists
RUN mkdir -p /root/ncs

WORKDIR /workspaces