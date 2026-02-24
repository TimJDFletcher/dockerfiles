# checkov Agent Documentation

Docker container for [Checkov](https://www.checkov.io/), a static analysis tool for infrastructure-as-code security scanning.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `python:3` (unpinned) |
| Package | `checkov` via pip (unpinned) |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/checkov:tmp` |
| `clean` | Remove images and prune builder |
| `release` | Multi-arch build/push to Docker Hub |

## Usage

```bash
# Scan current directory
docker run --rm -v $(pwd):/src timjdfletcher/checkov -d /src

# Scan specific file
docker run --rm -v $(pwd):/src timjdfletcher/checkov -f /src/main.tf
```

## Known Issues

- **Unpinned versions** — Both base image and checkov package are unpinned; builds are not reproducible
- **Dockerfile style** — Uses `ADD` instead of `COPY`, separate `chmod` instead of `COPY --chmod=`

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| checkov | https://pypi.org/project/checkov/ |
| Python base | https://hub.docker.com/_/python |

Pin versions in Dockerfile for reproducibility before updating.
