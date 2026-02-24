# goss Agent Documentation

Docker container for [goss](https://github.com/goss-org/goss), a YAML-based server testing framework.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:trixie-slim` (pinned via ARG) |
| Binary | `goss` downloaded from GitHub releases |

## Build Args

| Arg | Default | Purpose |
|-----|---------|---------|
| `DEBIAN_VERSION` | `trixie-slim` | Base image tag |
| `GOSS_VER` | `v0.4.9` | Goss release version |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/goss:tmp` |
| `test` | Build and run basic validation |
| `clean` | Remove images and prune builder |
| `release` | Test + multi-arch build/push to Docker Hub |

## Usage

```bash
# Run goss with mounted test file
docker run --rm \
  -v $(pwd)/tests:/tests:ro \
  timjdfletcher/goss \
  --gossfile /tests/goss.yaml validate

# Test a binary mounted from another container
docker run --rm \
  -v /path/to/binary:/usr/local/bin/mybinary:ro \
  -v $(pwd)/tests:/tests:ro \
  timjdfletcher/goss \
  --gossfile /tests/goss.yaml validate
```

## Note: Optional for Testing

This image is **no longer required** for running tests in other projects. All test suites now use a shared `goss-bin` Docker volume with goss downloaded directly from GitHub.

This image remains useful for:
- Direct command-line use
- Users who prefer a container over volume-based testing
- Reference implementation of goss packaging

## Updating Dependencies

| Dependency | ARG | Where to check |
|------------|-----|----------------|
| Goss | `GOSS_VER` | https://github.com/goss-org/goss/releases |
| Debian | `DEBIAN_VERSION` | https://hub.docker.com/_/debian |
