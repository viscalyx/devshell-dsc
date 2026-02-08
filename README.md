# DevShell DSC Container

Ubuntu 25.04 development environment with PowerShell, DSC v3, and Zsh (Oh My Zsh & Powerlevel10k) pre-configured.

## What's Included

- PowerShell 7.5.4 & DSC v3
- .NET SDK 9.0
- Git & OpenSSH Client
- Zsh with Oh My Zsh & Powerlevel10k
- Non-root `developer` user with sudo access

## Requirements

- Docker

## Quick Start

### Pull from Docker Hub

```bash
docker pull viscalyx/devshell-dsc:latest
```

### Run the Container

Run the Container to launch an interactive development shell with your local project mounted:

**Using Bash/Zsh:**

```bash
# Run interactively, mounting current directory to /home/developer/work
docker run --rm -it \
  -v "$(pwd)":/home/developer/work \
  viscalyx/devshell-dsc:latest
```

**Using PowerShell:**

```powershell
# Run interactively, mounting current directory to /home/developer/work
docker run --rm -it -v "${PWD}:/home/developer/work" viscalyx/devshell-dsc:latest
```

## Example Usage

1. From your development machine, clone a DSC resource repository:

   ```bash
   git clone git@github.com:dsccommunity/SqlServerDsc.git
   cd SqlServerDsc
   ```

1. Start the container with the cloned repository mounted:

   ```bash
   docker run --rm -it -v "$(pwd)":/home/developer/work viscalyx/devshell-dsc:latest
   ```

1. Once inside the container, for this example, start PowerShell

   ```bash
   pwsh
   ```

1. Build the project, and then list available DSC resources:

   ```powershell
   ./build.ps1 -ResolveDependency -Tasks build
   dsc resource list --adapter Microsoft.Dsc/PowerShell
   ```
