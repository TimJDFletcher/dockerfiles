# offlineimap Agent Documentation

Docker container for [offlineimap](https://www.offlineimap.org/), an IMAP synchronization tool with supercronic for scheduling.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:trixie-20260223-slim` |
| Packages | `offlineimap`, `ca-certificates`, `curl`, `procps` |
| Scheduler | `supercronic` v0.2.43 (downloaded from GitHub) |

## Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `DEBIAN_VERSION` | `trixie-20260223-slim` | Debian base image tag |
| `SUPERCRONIC_VERSION` | `v0.2.43` | Supercronic release version |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/offlineimap:tmp` |
| `test` | Build and run goss tests |
| `clean` | Remove images and prune builder |
| `release` | Test, build multi-arch, and push to Docker Hub |

## Testing

Tests use the shared `goss-bin` Docker volume. Validates:
- offlineimap binary exists and runs
- supercronic version matches
- entrypoint and crontab files exist
- offlineimap user created with correct home

## Usage

```bash
docker run -d \
  -v /path/to/config:/home/offlineimap/.offlineimaprc:ro \
  -v /path/to/email:/email \
  timjdfletcher/offlineimap
```

The container runs supercronic with `/etc/crontab` by default.

## Updating Dependencies

| Dependency | Where to check | Files to update |
|------------|----------------|-----------------|
| supercronic | https://github.com/aptible/supercronic/releases | `Dockerfile`, `run` |
| Debian base | https://hub.docker.com/_/debian | `Dockerfile` |

After updating, run `./run test` to validate.
