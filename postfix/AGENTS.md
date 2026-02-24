# postfix Agent Documentation

Docker container for [Postfix](http://www.postfix.org/), a mail transfer agent (MTA).

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:trixie-20260223-slim` |
| Packages | `postfix`, `iproute2` |

## Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `DEBIAN_VERSION` | `trixie-20260223-slim` | Debian base image tag |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/postfix:tmp` |
| `test` | Build and run goss tests |
| `clean` | Remove images and prune builder |
| `release` | Test, build multi-arch, and push to Docker Hub |

## Testing

Tests use the shared `goss-bin` Docker volume. Validates:
- postfix and iproute2 packages installed
- postfix binaries exist (`/usr/sbin/postfix`, `/usr/lib/postfix/sbin/master`)
- entrypoint exists with correct permissions
- postconf command works

## Usage

```bash
# Basic relay
docker run -d \
  -p 25:25 \
  -v /path/to/main.cf:/etc/postfix/main.cf:ro \
  timjdfletcher/postfix

# With custom config directory
docker run -d \
  -p 25:25 \
  -v /path/to/postfix-config:/etc/postfix:ro \
  timjdfletcher/postfix
```

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| Debian base | https://hub.docker.com/_/debian |

After updating, run `./run test` to validate.
