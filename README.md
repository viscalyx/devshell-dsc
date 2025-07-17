# DevShell DSC Container

A fully encapsulated Docker-based development environment optimized for consistency, reproducibility, and rapid onboarding.

## Included Tools

- PowerShell 7.5.2 & DSC v3 support
- .NET SDK 8.0
- Git
- Openssh Client
- Configured non-root 'developer' user with passwordless sudo
- Zsh & Oh My Zsh with autosuggestions, syntax-highlighting, fast-syntax-highlighting & zsh-autocomplete, and Powerlevel10k theme with MesloLGS NF fonts
- Health check via PowerShell

## Prerequisites

Ensure the following are installed on your host system:

- Docker (version >= 28.2)
- Docker Compose (version >= 2.36)

## Quick Start

Launch an interactive development shell with your project directory mounted:

```bash
# Standard user
docker-compose -f "${HOME}/source/devshell-dsc/docker-compose.yml" run --rm dev

# Root user
docker-compose -f "${HOME}/source/devshell-dsc/docker-compose.yml" run --rm --user root dev
```
