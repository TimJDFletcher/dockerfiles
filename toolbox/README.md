# Toolbox Docker Image

Generic Debian container with common debugging and networking tools. Useful as a sidecar or debug container.

## Usage

```bash
# Run interactively
docker run --rm -it timjdfletcher/toolbox bash

# Debug another container's network
docker run --rm -it \
  --net=container:<container_id> \
  timjdfletcher/toolbox

# Debug with full access to another container
docker run --rm -it \
  --pid=container:<container_id> \
  --net=container:<container_id> \
  -v /tmp/dump:/dump \
  timjdfletcher/toolbox

# Kubernetes debug container
kubectl debug -it <pod> --image=timjdfletcher/toolbox -- bash
```

## Included Tools

- `curl` — HTTP client
- `dnsutils` — dig, nslookup
- `jq` — JSON processor
- `less` — Pager
- `lsof` — List open files
- `net-tools` — netstat, ifconfig
- `procps` — ps, top, free
- `strace` — System call tracer
- `tcpdump` — Packet capture
- `vim` — Text editor

## Customization

Build with different tools:

```bash
docker build \
  --build-arg TOOLS="curl wget htop strace" \
  -t my-toolbox .
```

## Build

```bash
./run build
```

## Release

```bash
git tag toolbox-v<version>
./run release
```
