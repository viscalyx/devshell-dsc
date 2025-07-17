# DevShell DSC Container

Dockerized Ubuntu 24.04 dev environment with Zsh (Oh My Zsh & Powerlevel10k), PowerShell & DSC v3 pre-configured for seamless developer workflows.

## Included Tools

- PowerShell 7.5.2 & DSC v3 support
- .NET SDK 8.0
- Git
- OpenSSH Client
- Configured non-root 'developer' user with passwordless sudo
- Zsh & Oh My Zsh with autosuggestions, syntax-highlighting, fast-syntax-highlighting & zsh-autocomplete, and Powerlevel10k theme with MesloLGS NF fonts
- Health check via PowerShell

## Prerequisites

Ensure the following are installed on your host system:

- Docker (version >= 28.2)
- Docker Compose (version >= 2.36)

## Quick Start

Launch an interactive development shell with your project directory mounted:

>[!NOTE]
>The container will mount the directory you run this command from to `/home/developer/work`.

```bash
# Standard user
docker-compose -f "${HOME}/source/devshell-dsc/docker-compose.yml" run --rm dev

# Root user
docker-compose -f "${HOME}/source/devshell-dsc/docker-compose.yml" run --rm --user root dev
```
