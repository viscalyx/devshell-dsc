# DevShell DSC Container

Dockerized Ubuntu 24.04 dev environment with Zsh (Oh My Zsh & Powerlevel10k), PowerShell & DSC v3 pre-configured for seamless developer workflows.

## Included Tools

- PowerShell 7.5.2 & DSC v3 support
- .NET SDK 8.0
- Git
- OpenSSH Client
- Configured non-root 'developer' user with passwordless sudo
- Zsh & Oh My Zsh
- Health check via PowerShell

## Prerequisites

Ensure the following are installed on your host system:

- Docker

## Quick Start

Launch an interactive development shell with your project directory mounted:

## Pull and Run from Docker Hub

Use the published image from any local folder by pulling and running it with your current directory mounted:

```bash
# Pull the latest image
docker pull viscalyx/devshell-dsc:latest

# Run interactively, mounting current directory to /home/developer/work
docker run --rm -it \
  -v "$(pwd)":/home/developer/work \
  viscalyx/devshell-dsc:latest
```
