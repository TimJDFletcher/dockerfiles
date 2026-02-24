# tcpdump Agent Documentation

Minimal container for network packet capture using tcpdump.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:trixie-20260223-slim` |
| Package | `tcpdump` |

## Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `DEBIAN_VERSION` | `trixie-20260223-slim` | Debian base image tag |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/tcpdump:tmp` |
| `test` | Build and run goss + integration tests |
| `clean` | Remove images and prune builder |
| `release` | Test, build multi-arch, and push to Docker Hub |

## Testing

Tests run in two phases:

1. **Build-time tests (goss)** — Validates tcpdump binary exists and version check works
2. **Integration tests (docker-compose)** — Captures real HTTP traffic between containers

### Integration Test Architecture

```
docker-compose.yml
├── webserver (nginx:alpine)
│   └── Serves HTTP on port 80
├── tcpdump (shares webserver's network namespace)
│   └── Captures 5 packets to /capture/test.pcap
└── curl (external traffic generator)
    └── Makes HTTP requests to webserver
```

The key is `network_mode: "service:webserver"` which lets tcpdump see webserver's traffic.

## Usage

```bash
# Capture on host network
docker run --rm --net=host --cap-add=NET_RAW timjdfletcher/tcpdump -i eth0 -nn

# Capture another container's traffic
docker run --rm --net=container:myapp --cap-add=NET_RAW timjdfletcher/tcpdump -i eth0 -w /capture.pcap

# Write to file (mount a volume)
docker run --rm --net=host --cap-add=NET_RAW -v $(pwd):/data timjdfletcher/tcpdump -i eth0 -w /data/capture.pcap
```

Requires `--cap-add=NET_RAW` (or `--privileged`) for packet capture.

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| Debian base | https://hub.docker.com/_/debian |

After updating, run `./run test` to validate.
