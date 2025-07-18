# Contributing to devshell-dsc

Thank you for your interest in contributing to **devshell-dsc**! This guide explains how to test, run, and rebuild the development shell locally.

For any additional contributions, bug reports, or feature requests, please open an issue or pull request on the GitHub repository.

## Prerequisites

- Docker installed on your system.

## Clone GitHub repository

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
> To run from any directory, pass the path to the _docker-compose.yml_ where the repository was cloned, e.g. `-f "${HOME}/source/devshell-dsc/docker-compose.yml"`. The container will mount the directory you run this command from to `/home/developer/work`.

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

### Docker

```sh
docker build -t devshell:dsc .
```

### Docker Compose

```sh
docker compose build dev
```

### Docker (No Cache)

```sh
docker build --no-cache -t devshell:dsc .
```

### Docker Compose (No Cache)

```sh
docker compose build --no-cache dev
```

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
