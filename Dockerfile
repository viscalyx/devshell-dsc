# ---- Base image -------------------------------------------------------------
FROM ubuntu:24.04

ENV POWERSHELL_VERSION=7.5.2
ENV POWERSHELL_PACKAGE_REVISION=1
ENV DEBIAN_FRONTEND=noninteractive

# ---- Non‑interactive apt install -------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        zsh git curl wget ca-certificates locales lsb-release dotnet-sdk-8.0 sudo && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- Install PowerShell ----------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        echo "Installing .deb package for AMD64" && \
        wget https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell_${POWERSHELL_VERSION}-${POWERSHELL_PACKAGE_REVISION}.deb_amd64.deb -O powershell.deb && \
        dpkg -i powershell.deb && \
        rm powershell.deb && \
        apt-get update && apt-get install -f -y && \
        apt-get clean && rm -rf /var/lib/apt/lists/*; \
    elif [ "$ARCH" = "arm64" ]; then \
        echo "Installing tar.gz package for ARM64" && \
        wget https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-arm64.tar.gz -O powershell.tar.gz && \
        mkdir -p /opt/powershell && \
        tar -xzf powershell.tar.gz -C /opt/powershell && chmod +x /opt/powershell/pwsh && \
        ln -s /opt/powershell/pwsh /usr/bin/pwsh && \
        rm powershell.tar.gz; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi

# ---- Opinionated Oh My Zsh (unattended) ------------------------------------
RUN wget -q https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh -O /tmp/zsh-in-docker.sh && \
    sh /tmp/zsh-in-docker.sh -- -p git -p ssh-agent && \
    chsh -s /usr/bin/zsh root && \
    rm /tmp/zsh-in-docker.sh

# ---- PowerShell: ensure latest patch & install DSC v3 -----------------------
RUN pwsh -NoLogo -NoProfile -Command \
    'Install-PSResource PSDSC -TrustRepository -Quiet; Install-DscExe -IncludePrerelease -Force'

# ---- Verify & keep image slim ----------------------------------------------
RUN zsh --version && pwsh -NoLogo -Command '$PSVersionTable'

# ---- Healthcheck -----------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD pwsh -NoLogo -Command '$PSVersionTable | Out-Null || exit 1'

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# ---- Default shell ----------------------------------------------------------
CMD ["zsh"]

