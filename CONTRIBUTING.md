# Contributing to devshell-dsc

Thank you for your interest in contributing to **devshell-dsc**! This guide explains how to test, run, and rebuild the development shell locally.

For any additional contributions, bug reports, or feature requests, please open an issue or pull request on the GitHub repository.

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
> To securely inject secrets (e.g., GitHub tokens) without baking them into image layers or build history, enable BuildKit on every build. Do not use _Docker Compose_ v1 (`docker-compose`) because it does not support the secure arguments. Always use _Docker Compose_ v2 (`docker compose`).

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

### Prerequisites for Local Attestation Testing

- Docker BuildKit enabled (automatically enabled in modern Docker versions)
- Docker Scout CLI (optional, for local scanning)

### Building with Max-Mode Attestations

To build locally with the same attestation settings used in production:

```sh
# Basic build with max-mode attestations
DOCKER_BUILDKIT=1 docker build \
  --sbom=mode=max \
  --provenance=mode=max \
  -t devshell:dsc .
```

```sh
# No-cache build with max-mode attestations
DOCKER_BUILDKIT=1 docker build \
  --no-cache \
  --sbom=mode=max \
  --provenance=mode=max \
  -t devshell:dsc .
```

### Testing with Docker Scout Locally

If you have Docker Scout CLI installed, you can test the security scanning locally:

```sh
# Build with attestations
DOCKER_BUILDKIT=1 docker build \
  --sbom=mode=max \
  --provenance=mode=max \
  -t devshell:dsc .

# Scan for vulnerabilities
docker scout cves devshell:dsc

# Compare with latest published image (requires Docker Hub access)
docker scout compare devshell:dsc --to viscalyx/devshell-dsc:latest
```

> [!NOTE]
> Max-mode attestations add additional build time and storage overhead. They are primarily useful for:
>
> - Testing the full CI/CD security pipeline locally
> - Debugging attestation-related issues
> - Verifying Docker Scout integration before pushing changes
>
> For regular development and testing, the standard build commands without attestations are sufficient.

## Publishing

Publishing happens automatically when a GitHub release tag using semantic versioning in the format `v1.0.0` is created.

### Build

Build the `latest` tag:

```sh
docker build -t viscalyx/devshell-dsc:latest .
```

### Publish to Docker Hub

```sh
op item get "<item>" --field password --reveal | docker login --username viscalyx --password-stdin
docker push viscalyx/devshell-dsc:latest
```

Logout from Docker Hub:

```sh
docker logout
```

### Publish to GitHub Container Registry

**Required GitHub Token permissions**:

- **Packages**: Read & write
- **Packages**: Delete package versions (optional)
- (If publishing to a private repo) **Repository**: Read & write

>[!IMPORTANT]
>Currently only GitHub classic Personal Access Token works, not fine-grained Personal Access Tokens.

Tag the image for GHCR:

```sh
docker tag viscalyx/devshell-dsc:latest ghcr.io/viscalyx/devshell-dsc:latest
```

Login to GHCR and push:

```sh
op item get "<item>" --field password --reveal | docker login ghcr.io -u viscalyxbot --password-stdin
docker push ghcr.io/viscalyx/devshell-dsc:latest
```

Logout from GHCR:

```sh
docker logout ghcr.io
```

### Make GHCR Package Public

Once pushed, GHCR packages default to private. To switch to public:

- **Via GitHub UI**: Go to your GitHub account > Settings > Packages, select `devshell-dsc`, and change visibility to **Public**.

- **Via API** (classic PAT or GH_TOKEN with `packages:read` & `packages:write`):

```sh
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/packages/container/devshell-dsc/visibility \
  -d '{"visibility":"public"}'
```

- **Via GitHub CLI**:

```sh
gh api -X PUT /user/packages/container/devshell-dsc/visibility -F visibility=public
```

## Required Token Environment Variables

The following environment variables are required for CI/CD workflows and publishing tasks:

| Environment Variable | Description | Minimum Required Permissions |
|----------------------|-------------|------------------------------|
| `DOCKERHUB_TOKEN`   | Docker Hub personal access token used for authenticating with Docker Hub (login and updating description). | Write (push), Delete package versions (optional) |
| `GHCR_TOKEN`        | GitHub Container Registry token used for authenticating with ghcr.io (login and image push). | packages: write (and read), Delete package versions (optional) |
| `GH_READ_TOKEN`     | GitHub token used as to build container in GitHub Actions to read GitHUB API for `Install-DscExe` | public read-only |
| `GITHUB_TOKEN`      | Automatic GitHub Actions token used for API calls (e.g., changing GHCR package visibility). | contents: read, packages: write |
| `DOCKERHUB_USERNAME` | Docker Hub username used for authenticating with Docker Hub (login and updating description). | N/A |
| `GHCR_USERNAME`      | GitHub Container Registry username used for authenticating with ghcr.io (login and image push). | N/A |
