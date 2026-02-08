# Contributing to devshell-dsc

Thank you for your interest in contributing to **devshell-dsc**! This guide explains how to test, run, and rebuild the development shell locally.

For any additional contributions, bug reports, or feature requests, please open an issue or pull request on the GitHub repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Clone the GitHub repository](#clone-the-github-repository)
- [Running and Testing the DevShell Container](#running-and-testing-the-devshell-container)
- [Rebuilding the Container](#rebuilding-the-container)
- [Testing Max-Mode Attestations Locally](#testing-max-mode-attestations-locally)
- [Publishing](#publishing)
  - [Releasing a New Version](#releasing-a-new-version)
  - [What Happens After a Release](#what-happens-after-a-release)
  - [Verifying the Release](#verifying-the-release)
  - [Manual Build and Push (Not Recommended)](#manual-build-and-push-not-recommended)
- [Required Token Environment Variables](#required-token-environment-variables)

## Prerequisites

- Docker (v28 or higher)
- Docker Compose (v20 or higher)

## Clone the GitHub repository

Clone the repository via SSH:

```bash
git clone git@github.com:viscalyx/devshell-dsc.git
cd devshell-dsc
```

The commands below start the DevShell container in your _devshell-dsc_ project directory.

```bash
# Standard user
docker compose run --rm dev

# Root user
docker compose run --rm --user root dev
```

>[!IMPORTANT]
> If you want to start the container from any directory, pass the path to the repository’s `docker-compose.yml`, e.g.
> `-f "${HOME}/source/devshell-dsc/docker-compose.yml"`.
> The container mounts the directory you run the command from to `/home/developer/work`.

## Running and Testing the DevShell Container

To launch the development shell, run the following command in your terminal:

### Using Docker

To launch the container and log in as _root_:

```sh
docker run --rm -it devshell:dsc
```

### Using Docker Compose

To launch the container as **developer** with your current folder mounted at `/home/developer/work`:

```sh
docker compose run --rm dev
```

## Rebuilding the Container

> [!IMPORTANT]
> Docker Desktop 4.x and above has BuildKit enabled by default. For older Docker versions or CLI, enable BuildKit by prefixing builds with `DOCKER_BUILDKIT=1`. Docker Compose v1 (`docker-compose`) does not support secure build arguments; use Compose v2 (`docker compose`). For more details, see [Docker Build Enhancements docs](https://docs.docker.com/develop/develop-images/build_enhancements/).

### Docker

```sh
DOCKER_BUILDKIT=1 docker build -t devshell:dsc .
```

### Docker Compose

```sh
docker compose build dev
```

### Docker (No Cache)

```sh
DOCKER_BUILDKIT=1 docker build --no-cache -t devshell:dsc .
```

### Docker Compose (No Cache)

```sh
docker compose build --no-cache dev
```

## Testing Max-Mode Attestations Locally

Max-mode attestations are automatically enabled in CI/CD workflows for production builds and security scanning. However, developers can test these locally to verify Docker Scout integration or troubleshoot attestation-related issues.

Max-mode attestations add additional build time and storage overhead. They are primarily useful for:

- Testing the full CI/CD security pipeline locally
- Debugging attestation-related issues
- Verifying Docker Scout integration before pushing changes

For regular development and testing, the standard build commands without attestations are sufficient.

### Prerequisites for Local Attestation Testing

- Docker Desktop with containerd image store enabled
- Docker BuildKit enabled (automatically enabled in modern Docker versions)
- Docker Scout CLI (optional, for local scanning)

### Enable Containerd Image Store in Docker Desktop

Max-mode attestations require the containerd image store to be enabled in Docker Desktop:

1. Open **Docker Desktop**
1. Go to **Settings** → **General**
1. Enable **"Use containerd for pulling and storing images"**
1. Click **Apply & restart**
1. Wait for Docker Desktop to restart

> [!IMPORTANT]
> Without enabling the containerd image store, you will get the error: "Attestation is not supported for the docker driver. Switch to a different driver, or turn on the containerd image store, and try again."

### Building with Max-Mode Attestations

To build locally with the same attestation settings used in production:

```sh
# Basic build with max-mode attestations
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --sbom=mode=max \
  --provenance=mode=max \
  --tag devshell-dsc-dev:latest \
  --load \
  .
```

```sh
# No-cache build with max-mode attestations
docker buildx build \
  --platform linux/amd64,linux/arm64  \
  --sbom=mode=max \
  --provenance=mode=max \
  --tag devshell-dsc-dev:latest \
  --no-cache \
  --load \
  .
```

### Testing with Docker Scout Locally

After building your image with max-mode attestations (see “Building with Max-Mode Attestations”), scan locally:

```sh
# Quickview the image with Docker Scout
docker scout quickview local://devshell-dsc-dev:latest

# Scan vulnerabilities using local locator
docker scout cves local://devshell-dsc-dev:latest

# View base image update recommendations
docker scout recommendations local://devshell-dsc-dev:latest

# Quickview with organization policies applied
docker scout quickview local://devshell-dsc-dev:latest --org viscalyx
```

#### Compare against the latest published image (requires Docker Hub access)

```sh
# Compare against the latest published image (requires Docker Hub access)
docker scout compare local://devshell-dsc-dev:latest --to registry://docker.io/viscalyx/devshell-dsc:latest
```

## Publishing

Publishing happens automatically when a GitHub release tag using semantic versioning in the format `v1.0.0` is created. Images are published to both **Docker Hub** (`docker.io/viscalyx/devshell-dsc`) and **GitHub Container Registry** (`ghcr.io/viscalyx/devshell-dsc`).

### Releasing a New Version

1. **Ensure all changes are merged to `main`.**
   All pull requests should pass the CI checks (Dockerfile linting via hadolint
   and a build verification) before merging.

2. **Create and push a semantic version tag.**

   ```sh
   git checkout main
   git pull origin main
   git tag v1.2.3
   git push origin v1.2.3
   ```

3. **The publish workflow runs automatically.**
   Pushing the `v*.*.*` tag triggers the
   [docker-publish.yml](/.github/workflows/docker-publish.yml) workflow which
   builds and pushes multi-platform images.

> [!NOTE]
> The publish workflow can also be triggered manually from the **Actions** tab
> using the **workflow_dispatch** trigger.

### What Happens After a Release

When a tag matching `v*.*.*` is pushed, the publish workflow:

1. **Builds multi-platform images** for `linux/amd64` and `linux/arm64` using
   Docker Buildx with QEMU emulation.
2. **Generates max-mode attestations** (SBOM and provenance) for Docker Scout
   security scanning.
3. **Pushes to both registries** with the following tags:

   | Trigger | Tags Applied |
   |---------|-------------|
   | Tag push (e.g., `v1.2.3`) | `v1.2.3` + `latest` |
   | Push to `main` | `main` |

   For example, releasing `v1.2.3` produces:
   - `docker.io/viscalyx/devshell-dsc:v1.2.3`
   - `docker.io/viscalyx/devshell-dsc:latest`
   - `ghcr.io/viscalyx/devshell-dsc:v1.2.3`
   - `ghcr.io/viscalyx/devshell-dsc:latest`

4. **Updates the Docker Hub description** if `README.md` was modified (handled
   by a separate workflow on pushes to `main`).

> [!IMPORTANT]
> Build caching is intentionally disabled for tagged releases to ensure the
> latest versions of all packages are installed fresh.

### Verifying the Release

After the workflow completes, verify the published images:

```sh
# Pull and verify from Docker Hub
docker pull viscalyx/devshell-dsc:latest
docker run --rm viscalyx/devshell-dsc:latest pwsh -NoLogo -NoProfile -Command '$PSVersionTable'

# Pull and verify from GHCR
docker pull ghcr.io/viscalyx/devshell-dsc:latest
```

You can also scan the published image with Docker Scout:

```sh
docker scout quickview registry://docker.io/viscalyx/devshell-dsc:latest
docker scout cves registry://docker.io/viscalyx/devshell-dsc:latest
```

### Manual Build and Push (Not Recommended)

For regular releases, always use the automated workflow above. If you need to
push manually for debugging purposes:

```sh
# Build the latest tag
docker build -t viscalyx/devshell-dsc:latest .

# Push to Docker Hub
docker push viscalyx/devshell-dsc:latest
```

## Required Token Environment Variables

The following environment variables are required for CI/CD workflows and publishing tasks:

| Environment Variable | Description | Minimum Required Permissions |
| ---------------------- | ------------- | ------------------------------ |
| `DOCKERHUB_TOKEN` | Docker Hub personal access token used for authenticating with Docker Hub (login and updating description). | Write (push), Delete package versions (optional) |
| `GHCR_TOKEN` | GitHub Container Registry token used for authenticating with ghcr.io (login and image push). | packages: write (and read), Delete package versions (optional) |
| `GH_READ_TOKEN` | GitHub token used as to build container in GitHub Actions to read GitHUB API for `Install-DscExe` | public read-only |
| `GITHUB_TOKEN` | Automatic GitHub Actions token used for API calls (e.g., changing GHCR package visibility). | contents: read, packages: write |
| `DOCKERHUB_USERNAME` | Docker Hub username used for authenticating with Docker Hub (login and updating description). | N/A |
| `GHCR_USERNAME` | GitHub Container Registry username used for authenticating with ghcr.io (login and image push). | N/A |
