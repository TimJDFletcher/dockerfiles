# Goss Agent Documentation

Builds [goss](https://github.com/goss-org/goss) from source with updated dependencies to fix CVEs. The resulting scratch image contains only the static goss binary.

## Purpose

Pre-built goss releases contain vulnerable Go dependencies. This project compiles goss with the latest Go version and updates vulnerable dependencies (e.g., `golang.org/x/crypto`) before building.

## Usage

Other Dockerfiles can copy the goss binary:

```dockerfile
COPY --from=timjdfletcher/goss:latest /goss /path/to/goss
```

Or use in a multi-stage build:

```dockerfile
FROM timjdfletcher/goss:latest AS goss
FROM debian:trixie-slim
COPY --from=goss /goss /usr/local/bin/goss
```

## Build Arguments

| ARG | Default | Description |
|-----|---------|-------------|
| `GO_VERSION` | `1.26` | Go version for compilation |
| `GOSS_VERSION` | `v0.4.9` | Goss release tag to build from |

## Developer Workflow

| Command | Description |
|---------|-------------|
| `./run build` | Build local image |
| `./run test` | Build, test version/help, run trivy scan |
| `./run clean` | Remove images |
| `./run release` | Test + multi-arch push to Docker Hub |

## Updating Dependencies

The Dockerfile runs `go get golang.org/x/crypto@latest` before building to pull the latest patched version. To update goss itself:

1. Check https://github.com/goss-org/goss/releases for new versions
2. Update `GOSS_VERSION` in the `run` script
3. Run `./run test` to verify

## Security

The build:
- Uses `CGO_ENABLED=0` for a fully static binary
- Strips debug info with `-ldflags "-s -w"`
- Updates vulnerable dependencies before compilation
- Runs trivy scan as part of `./run test`
