# Container Testing with Goss

A reusable testing pattern for Docker containers using [goss](https://github.com/goss-org/goss), a YAML-based server validation tool.

## Overview

This skill provides a consistent approach to testing Docker containers:
- **Pre-built goss image** with patched Go dependencies (no CVEs)
- **Works with any container** including minimal/scratch images
- **Fast iteration** with cached binary extraction
- **Two patterns**: embedded (in image) or external (mounted at test time)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              timjdfletcher/goss:tmp image                   │
│              (built from ../goss project)                   │
│                Contains: /goss binary                       │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
┌───────────────────────────┐       ┌───────────────────────────┐
│  Pattern 1: Embedded      │       │  Pattern 2: External      │
│  (services with health)   │       │  (CLI tools, tests)       │
│                           │       │                           │
│  COPY --from=goss /goss   │       │  Extract goss to .goss-bin│
│  into Dockerfile          │       │  Mount at test time       │
└───────────────────────────┘       └───────────────────────────┘
```

## Prerequisites

Build the goss image first:

```bash
cd /path/to/dockerfiles/goss
./run build
```

## Pattern 1: Embedded Goss (Services)

For long-running services that need:
- Build-time validation
- Docker HEALTHCHECK
- Live integration tests

### Dockerfile Structure

```dockerfile
# Reference the pre-built goss image
FROM timjdfletcher/goss:latest AS goss

FROM debian:trixie-slim

ARG GOSS_VER="v0.4.9-patched"
ARG GOSS_DST="/goss"

ENV GOSS_VER=${GOSS_VER} \
    GOSS_DST=${GOSS_DST}

# Copy goss binary from pre-built image (no curl needed!)
COPY --from=goss /goss ${GOSS_DST}/goss

# Install your application
RUN apt-get update && apt-get install -y myservice && \
    rm -rf /var/lib/apt/lists/*

# Copy goss tests
COPY goss/tests/ ${GOSS_DST}/tests/

COPY entrypoint /entrypoint

# Build-time validation
RUN ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate

# Runtime healthcheck
HEALTHCHECK --interval=1m --timeout=10s \
  CMD ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-healthcheck-tests.yaml validate || exit 1

ENTRYPOINT ["/entrypoint"]
```

### Test File Types

| File | Purpose | When Run |
|------|---------|----------|
| `goss-dockerfile-tests.yaml` | Validate image structure | Build time (`RUN goss validate`) |
| `goss-healthcheck-tests.yaml` | Validate running service | Docker HEALTHCHECK (continuous) |
| `goss-live-tests.yaml` | Full integration tests | `docker compose exec` (manual/CI) |

### Example: samba-timemachine

See `samba-timemachine/` for a complete implementation of this pattern.

## Pattern 2: External Goss (CLI Tools)

For containers where you don't embed goss, extract it at test time.

### Setup

Add this function to your `./run` script:

```bash
GOSS_IMAGE="timjdfletcher/goss"
IMAGE_TAG="tmp"

_ensure_goss() {
  local goss_dir="${PWD}/.goss-bin"
  if [ ! -x "${goss_dir}/goss" ]; then
    log "Extracting goss from ${GOSS_IMAGE}:${IMAGE_TAG}..."
    mkdir -p "${goss_dir}"
    docker create --name goss-extract "${GOSS_IMAGE}:${IMAGE_TAG}" >/dev/null
    docker cp goss-extract:/goss "${goss_dir}/goss"
    docker rm goss-extract >/dev/null
  fi
}
```

### Test Function (Containers WITH Shell)

```bash
test() {
  build
  _ensure_goss

  log "Running goss tests..."
  docker run --rm \
    -v "${PWD}/.goss-bin:/goss-bin:ro" \
    -v "${PWD}/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}
```

### Test Function (Scratch/Distroless Containers)

```bash
test() {
  build
  _ensure_goss

  log "Extracting binary from scratch container..."
  mkdir -p .tmp
  trap "rm -rf .tmp" EXIT

  local tmp_container
  tmp_container=$(docker create "${IMAGE_NAME}:${IMAGE_TAG}")
  docker cp "${tmp_container}:/myapp" ".tmp/myapp"
  docker rm "${tmp_container}" >/dev/null
  chmod 755 ".tmp/myapp"

  log "Running goss tests..."
  docker run --rm \
    -v "${PWD}/.goss-bin:/goss-bin:ro" \
    -v "${PWD}/.tmp/myapp:/usr/local/bin/myapp:ro" \
    -v "${PWD}/goss/tests:/goss:ro" \
    debian:trixie-slim \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}
```

### .gitignore

Add to project `.gitignore`:

```
.goss-bin/
.tmp/
```

## Pattern 3: Integration Tests with Docker Compose

### docker-compose.yml

```yaml
services:
  myservice:
    image: myimage:tmp
    build:
      context: .
    volumes:
      - ./.goss-bin:/goss-bin:ro
      - ./goss/tests:/goss/tests:ro
    environment:
      - APP_USER=testuser
      - PORT=8080
```

### Test Function

```bash
test() {
  build
  _ensure_goss

  log "Starting test environment..."
  docker compose up -d --wait

  log "Running integration tests..."
  docker compose exec -T myservice /goss-bin/goss \
    --gossfile /goss/tests/goss-integration-tests.yaml validate

  log "Cleaning up..."
  docker compose down

  log "All tests passed!"
}
```

## Test File Organization

```
project/
├── Dockerfile
├── run
├── .gitignore          # Include .goss-bin/, .tmp/
└── goss/
    └── tests/
        ├── goss-dockerfile-tests.yaml    # Build-time validation
        ├── goss-healthcheck-tests.yaml   # Service health (if embedded)
        └── goss-live-tests.yaml          # Full integration tests
```

## Goss Test Types

| Type | Use Case | Example |
|------|----------|---------|
| `file` | Check file exists, permissions, content | Entrypoint, config files |
| `command` | Run command, check exit code and output | Version checks, help output |
| `package` | Verify package installed (apt/yum) | Runtime dependencies |
| `user` | Check user exists, uid, groups | Non-root user setup |
| `port` | Check port is listening | Service readiness |
| `http` | HTTP request validation | API endpoints |
| `process` | Check process running | Daemons |

## Example Test File

`goss/tests/goss-dockerfile-tests.yaml`:

```yaml
file:
  /entrypoint:
    exists: true
    mode: "0755"

command:
  myapp --version:
    exit-status: 0
    stdout:
      - "1.2.3"
    timeout: 5000

  myapp --help:
    exit-status: 0
    stdout:
      - "Usage:"
    timeout: 5000

package:
  myapp:
    installed: true
  # Build tools should be purged
  curl:
    installed: false
```

## TDD Workflow

1. **Write test first** — Define expected behavior in goss YAML
2. **Run test** — Verify it fails (red)
3. **Implement fix** — Update Dockerfile/code
4. **Run test** — Verify it passes (green)
5. **Commit** — Include both test and fix

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `goss: not found` | Run `_ensure_goss` or check volume mount path |
| Permission denied | Check `.goss-bin/goss` has execute permission |
| goss-extract container exists | Run `docker rm goss-extract` |
| Tests pass locally, fail in CI | Ensure goss image is built in CI first |

## References

- [goss documentation](https://github.com/goss-org/goss)
- [goss manual](https://goss.rocks/)
- [dgoss (Docker wrapper)](https://github.com/goss-org/goss/tree/master/extras/dgoss)
