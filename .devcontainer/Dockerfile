FROM zephyrprojectrtos/zephyr-build:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

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
    cd / && rm -rf "${NCLT_TMP}"