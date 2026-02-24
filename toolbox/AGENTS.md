# toolbox Agent Documentation

Generic Debian container with common debugging and networking tools. Designed to run as a sidecar or exec target for troubleshooting.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:stable-slim` |
| Tools | Configured via `TOOLS` build arg |

Default tools: `ca-certificates curl dnsutils jq less lsof mmc-utils net-tools procps strace tcpdump vim`

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/toolbox:tmp` |
| `clean` | Remove images and prune builder |
| `release` | Multi-arch build/push to Docker Hub |

## Usage

```bash
# Run interactively
docker run --rm -it timjdfletcher/toolbox bash

# Run as sidecar in same network namespace
docker run --rm -it --net=container:<target> timjdfletcher/toolbox

# Kubernetes debug container
kubectl debug -it <pod> --image=timjdfletcher/toolbox
```

## Customization

Build with different tools:

```bash
docker build --build-arg TOOLS="curl wget htop" -t custom-toolbox .
```

## Behavior

The entrypoint runs a sleep loop if no command is provided, keeping the container alive for `docker exec`.
