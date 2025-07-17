# Contributing to devshell-dsc

Thank you for your interest in contributing to **devshell-dsc**! This guide explains how to test, run, and rebuild the development shell locally.

## Prerequisites

- Docker installed on your system.

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
docker-compose run --rm dev
```

## Rebuilding the Container

### Docker

```sh
docker build -t devshell:dsc .
```

### Docker Compose

```sh
docker-compose build dev
```

### Docker (No Cache)

```sh
docker build --no-cache -t devshell:dsc .
```

### Docker Compose (No Cache)

```sh
docker-compose build --no-cache dev
```

---

For any additional contributions, bug reports, or feature requests, please open an issue or pull request on the GitHub repository.
