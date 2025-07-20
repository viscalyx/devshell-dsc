# syntax=docker/dockerfile:experimental
# ---- Base image -------------------------------------------------------------
FROM ubuntu:24.04
LABEL org.opencontainers.image.source="https://github.com/viscalyx/devshell-dsc"

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

ENV POWERSHELL_VERSION=7.5.2
ENV POWERSHELL_PACKAGE_REVISION=1
ENV DEBIAN_FRONTEND=noninteractive

# ---- Non-interactive apt install -------------------------------------------
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        zsh git curl wget ca-certificates locales lsb-release fontconfig dotnet-sdk-8.0 sudo vim \
        openssh-client && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- Install PowerShell ----------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        echo "Installing .deb package for AMD64" && \
        wget --progress=dot:giga https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell_${POWERSHELL_VERSION}-${POWERSHELL_PACKAGE_REVISION}.deb_amd64.deb -O powershell.deb && \
        dpkg -i powershell.deb && \
        rm powershell.deb && \
        apt-get update && apt-get install -f -y --no-install-recommends && \
        apt-get clean && rm -rf /var/lib/apt/lists/*; \
    elif [ "$ARCH" = "arm64" ]; then \
        echo "Installing tar.gz package for ARM64" && \
        wget --progress=dot:giga https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-arm64.tar.gz -O powershell.tar.gz && \
        mkdir -p /opt/powershell && \
        tar -xzf powershell.tar.gz -C /opt/powershell && chmod +x /opt/powershell/pwsh && \
        ln -s /opt/powershell/pwsh /usr/bin/pwsh && \
        rm powershell.tar.gz; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi

# ---- Verify & keep image slim ----------------------------------------------
# shellcheck disable=SC2154
 RUN zsh --version && pwsh -NoLogo -Command "\$PSVersionTable"

# ---- Opinionated Oh My Zsh (unattended) ------------------------------------
RUN sh -c "$(wget --progress=dot:giga -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" && \
    git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting "${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" && \
    git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete "${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-autocomplete" && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/themes/powerlevel10k" && \
    # Install Powerlevel10k MesloLGS NF fonts
    for variant in Regular Bold Italic "Bold Italic"; do \
      encoded=${variant// /%20}; \
      wget --progress=dot:giga -O "/tmp/MesloLGS_NF_${variant// /_}.ttf" \
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${encoded}.ttf"; \
    done && \
    mkdir -p /usr/share/fonts/truetype/powerlevel10k && \
    mv /tmp/*.ttf /usr/share/fonts/truetype/powerlevel10k/ && \
    fc-cache -fv

# Add custom Powerlevel10k config
COPY .pk10k.zsh /root/.p10k.zsh

COPY instant-prompt.zsh /root/instant-prompt.zsh

RUN chsh -s /usr/bin/zsh root && \
    # configure default theme and plugins for root
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /root/.zshrc && \
    sed -i 's|^plugins=.*|plugins=(git ssh-agent zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)|' /root/.zshrc && \
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> /root/.zshrc && \
    # Prepend Powerlevel10k instant prompt block to root .zshrc using project file
    cat /root/instant-prompt.zsh /root/.zshrc > /root/.zshrc.tmp && mv /root/.zshrc.tmp /root/.zshrc

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
    echo 'export EDITOR=vim' >> /root/.zshrc && \
    echo 'export VISUAL=vim' >> /root/.zshrc && \
    echo 'export DEBIAN_FRONTEND=dialog' >> /root/.zshrc && \
    # Automatically cd into ~/source if it exists
    echo 'if [[ -d ~/source ]]; then' >> /root/.zshrc && \
    echo '  cd ~/source' >> /root/.zshrc && \
    echo 'elif [[ -d ~/work ]]; then' >> /root/.zshrc && \
    echo '  cd ~/work' >> /root/.zshrc && \
    echo 'fi' >> /root/.zshrc

# ---- PowerShell: ensure latest patch & install DSC v3 using BuildKit secret ----
# hadolint ignore=SC2154
RUN --mount=type=secret,id=gh_read_token pwsh -NoLogo -NoProfile -Command "\$ErrorActionPreference='Stop'; Install-PSResource 'PSDSC' -TrustRepository -Quiet -ErrorAction 'Stop'; if(Test-Path '/run/secrets/gh_read_token'){ \$plainToken=(Get-Content '/run/secrets/gh_read_token' -Raw).Trim(); \$secureToken=ConvertTo-SecureString \$plainToken -AsPlainText -Force; Install-DscExe -IncludePrerelease -Force -ErrorAction 'Stop' -Token \$secureToken } else { Install-DscExe -IncludePrerelease -Force -ErrorAction 'Stop' }"

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# ---- Create non-root user 'developer' with sudo privileges ----
RUN useradd -ms /usr/bin/zsh developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/developer && \
    echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' > /etc/sudoers.d/secure_path && \
    chmod 0440 /etc/sudoers.d/developer /etc/sudoers.d/secure_path

# ---- Copy root’s config to the user 'developer' ----
RUN cp -R /root/.oh-my-zsh /home/developer/ && \
    cp /root/.zshrc /home/developer/.zshrc && \
    cp /root/.p10k.zsh /home/developer/.p10k.zsh && \
    touch /home/developer/.zprofile /home/developer/.zshenv /home/developer/.zlogin && \
    sed -i "s|^export ZSH=.*|export ZSH=\"\$HOME/.oh-my-zsh\"|" /home/developer/.zshrc && \
    chown -R developer:developer /home/developer && \
    mkdir -p /home/developer/.ssh && chmod 700 /home/developer/.ssh && chown developer:developer /home/developer/.ssh

USER developer
WORKDIR /home/developer

# ---- Healthcheck -----------------------------------------------------------
 HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD pwsh -NoLogo -Command "\$PSVersionTable | Out-Null || exit 1"

# ---- Default shell ----------------------------------------------------------
CMD ["zsh"]

