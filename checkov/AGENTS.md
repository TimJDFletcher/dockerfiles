# checkov Agent Documentation

Docker container for [Checkov](https://www.checkov.io/), a static analysis tool for infrastructure-as-code security scanning.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `python:3.13.12-slim` |
| Package | `checkov==3.2.506` via pip |

## Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `PYTHON_VERSION` | `3.13.12-slim` | Python base image tag |
| `CHECKOV_VERSION` | `3.2.506` | Checkov package version |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/checkov:tmp` |
| `test` | Build and run goss tests |
| `clean` | Remove images and prune builder |
| `release` | Test, then multi-arch build/push to Docker Hub |

## Testing

Tests run in two phases:
1. **Direct artifact tests** — Verify version output and help work
2. **Goss tests** — Run inside container validating entrypoint permissions and checkov behavior

Test files are in `goss/tests/goss-dockerfile-tests.yaml`. The goss binary is injected via a shared `goss-bin` Docker volume (created automatically on first test run).

## Usage

```bash
# Scan current directory
docker run --rm -v $(pwd):/src timjdfletcher/checkov -d /src

# Scan specific file
docker run --rm -v $(pwd):/src timjdfletcher/checkov -f /src/main.tf
```

## Updating Dependencies

| Dependency | Where to check | Files to update |
|------------|----------------|-----------------|
| checkov | https://pypi.org/project/checkov/ | `Dockerfile`, `run` (CHECKOV_VERSION), `goss/tests/goss-dockerfile-tests.yaml` |
| Python base | https://hub.docker.com/_/python | `Dockerfile` |

After updating, run `./run test` to validate.
