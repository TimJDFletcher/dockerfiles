# tcpdump Docker Image

Minimal container for network packet capture using tcpdump.

## Usage

```bash
# Capture on host network
docker run --rm --net=host --cap-add=NET_RAW timjdfletcher/tcpdump

# Capture on a specific interface
docker run --rm --net=host --cap-add=NET_RAW timjdfletcher/tcpdump -i eth0 -nn

# Capture from another container's network namespace
docker run --rm --net=container:<container_id> --cap-add=NET_RAW timjdfletcher/tcpdump

# Write to file (mount a volume)
docker run --rm --net=host --cap-add=NET_RAW \
  -v $(pwd):/data \
  timjdfletcher/tcpdump -i eth0 -w /data/capture.pcap
```

## Required Capabilities

The container requires `NET_RAW` capability for packet capture:

```bash
--cap-add=NET_RAW
```

Or run with `--privileged` (not recommended for production).

## Default Command

By default, the container runs:

```bash
tcpdump -i eth0 -p -nn
```

- `-i eth0` — Capture on eth0
- `-p` — Don't put interface in promiscuous mode
- `-nn` — Don't resolve hostnames or port names
