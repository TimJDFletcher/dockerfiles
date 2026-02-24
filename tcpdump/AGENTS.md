# tcpdump Agent Documentation

Minimal container for network packet capture using tcpdump.

## Core Components

* **Base Image:** `debian:trixie-slim`
* **Package:** `tcpdump`

## Usage

```bash
docker run --rm --net=host --cap-add=NET_RAW timjdfletcher/tcpdump -i eth0 -nn
```

Requires `--cap-add=NET_RAW` (or `--privileged`) for packet capture.

## Proposed Testing (Not Implemented)

Adding goss would increase image size ~15MB. If testing is desired:

**Build-time tests:**
- `tcpdump` package installed
- `/usr/bin/tcpdump` exists with mode 0755
- `tcpdump --version` exits 0
- `/var/lib/apt/lists` is empty (apt cache cleaned)

**Runtime tests** (require `--cap-add=NET_RAW`):
- `tcpdump -D` lists interfaces
- `tcpdump -i any -c 0 -nn` parses args correctly

Given the container's simplicity, manual testing is likely sufficient.
