# Container Testing with Goss

A reusable testing pattern for Docker containers using [goss](https://github.com/goss-org/goss), a YAML-based server validation tool.

## Overview

This skill provides a consistent approach to testing Docker containers:
- **Official goss image** (`ghcr.io/goss-org/goss`), pinned by tag and digest
- **Works with any container** including minimal/scratch images
- **Fast iteration** with cached binary extraction
- **Multiple patterns**: embedded, external mount, or GitHub download

### Pattern Summary

| Pattern | Use Case | Goss Source |
|---------|----------|-------------|
| 1. Embedded | Services with healthcheck | `COPY --from=goss` in Dockerfile |
| 2. External | CLI tools in this monorepo | Extract from `ghcr.io/goss-org/goss` image |
| 3. Compose | Integration tests | Mount `.goss-bin/` in compose |
| 4. GitHub | Standalone/external projects | Download from GitHub releases |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              ghcr.io/goss-org/goss image                    │
│              (official release, pinned by digest)           │
│                Contains: /usr/bin/goss binary               │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
┌───────────────────────────┐       ┌───────────────────────────┐
│  Pattern 1: Embedded      │       │  Pattern 2: External      │
│  (services with health)   │       │  (CLI tools, tests)       │
│                           │       │                           │
│  COPY --from=goss         │       │  Extract goss to .goss-bin│
│  into Dockerfile          │       │  Mount at test time       │
└───────────────────────────┘       └───────────────────────────┘
```

## Prerequisites

Docker only. The goss image is pinned by tag **and** multi-arch index digest, so every pull is integrity-checked:

```
ghcr.io/goss-org/goss:v0.4.10@sha256:8d3924f722a04a660e9e6c2403be0399d737c0187fc065714d26b992286c3f0a
```

To bump it, find the new tag at https://github.com/goss-org/goss/releases and resolve its digest with `docker buildx imagetools inspect ghcr.io/goss-org/goss:<tag>`.

## Pattern 1: Embedded Goss (Services)

For long-running services that need:
- Build-time validation
- Docker HEALTHCHECK
- Live integration tests

### Dockerfile Structure

```dockerfile
# Official goss image, pinned by digest
ARG GOSS_IMAGE="ghcr.io/goss-org/goss:v0.4.10@sha256:8d3924f722a04a660e9e6c2403be0399d737c0187fc065714d26b992286c3f0a"
FROM ${GOSS_IMAGE} AS goss

FROM debian:trixie-slim

# Must match `goss --version` output (no leading "v")
ARG GOSS_VER="0.4.10"
ARG GOSS_DST="/goss"

ENV GOSS_VER=${GOSS_VER} \
    GOSS_DST=${GOSS_DST}

# Copy goss binary from the official image (no curl needed!)
COPY --from=goss /usr/bin/goss ${GOSS_DST}/goss

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
GOSS_IMAGE="${GOSS_IMAGE:-ghcr.io/goss-org/goss:v0.4.10@sha256:8d3924f722a04a660e9e6c2403be0399d737c0187fc065714d26b992286c3f0a}"

_ensure_goss() {
  local goss_dir="${PWD}/.goss-bin"
  # Re-extract when the pinned image changes so a stale cached binary isn't reused
  if [ ! -x "${goss_dir}/goss" ] || [ "$(cat "${goss_dir}/.image" 2>/dev/null)" != "${GOSS_IMAGE}" ]; then
    log "Extracting goss from ${GOSS_IMAGE}..."
    mkdir -p "${goss_dir}"
    docker rm goss-extract 2>/dev/null || true
    docker create --name goss-extract "${GOSS_IMAGE}" >/dev/null
    docker cp goss-extract:/usr/bin/goss "${goss_dir}/goss"
    docker rm goss-extract >/dev/null
    echo "${GOSS_IMAGE}" > "${goss_dir}/.image"
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

## Pattern 4: Download from GitHub Releases (Standalone)

When the `ghcr.io/goss-org/goss` image can't be pulled, download goss directly from GitHub releases. Releases ship `goss_<ver>_linux_<arch>.tar.gz` archives plus a `goss_<ver>_SHA256SUMS` file; the tarball is checksum-verified before extraction.

### Shared Volume Pattern

Uses a Docker volume to cache the goss binary across test runs:

```bash
GOSS_VERSION="v0.4.10"

_get_goss_arch() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64)  echo "x86_64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    armv7l)  echo "armv6" ;;
    armv6l)  echo "armv6" ;;
    *)       echo "x86_64" ;;
  esac
}

_ensure_goss_volume() {
  local goss_arch
  goss_arch=$(_get_goss_arch)

  # Create volume if missing
  if ! docker volume inspect goss-bin >/dev/null 2>&1; then
    log "Creating goss-bin volume..."
    docker volume create goss-bin

    # Set permissions for curlimages/curl user (uid 101:102)
    # This allows downloading without running as root
    docker run --rm -v goss-bin:/target alpine:latest chown 101:102 /target
  fi

  # Download goss if missing or wrong version. Releases ship tarballs plus a
  # SHA256SUMS file; the tarball is verified before extracting.
  local ver="${GOSS_VERSION#v}"
  local base="https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}"
  local archive="goss_${ver}_linux_${goss_arch}.tar.gz"
  log "Ensuring goss ${GOSS_VERSION} in volume..."
  docker run --rm \
    -v goss-bin:/target \
    --entrypoint sh \
    curlimages/curl:latest -c "
      set -e
      if [ -f /target/goss ] && /target/goss --version 2>&1 | grep -q 'version ${ver}\$'; then
        echo 'goss ${GOSS_VERSION} already installed'
      else
        cd /tmp
        curl -fsSLO \"${base}/${archive}\"
        curl -fsSLO \"${base}/goss_${ver}_SHA256SUMS\"
        grep ' ${archive}\$' goss_${ver}_SHA256SUMS | sha256sum -c -
        tar -xzf ${archive} -C /target goss
        chmod 755 /target/goss
        echo 'goss ${GOSS_VERSION} installed'
      fi
    "
}
```

### Test Function

```bash
test() {
  build
  _ensure_goss_volume

  log "Running goss tests..."
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "${PWD}/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}
```

### Docker Compose with External Volume

```yaml
services:
  myservice:
    image: myimage:tmp
    volumes:
      - goss-bin:/goss-bin:ro
      - ./goss/tests:/goss/tests:ro

volumes:
  goss-bin:
    external: true
```

### Security Note

This pattern downloads from the internet during test runs. To avoid running curl as root:
1. Volume permissions are set once using `alpine` as root
2. Subsequent downloads use `curlimages/curl` which runs as non-root (uid 101)

### When to Use This Pattern

- Projects outside this monorepo
- Environments that can't pull from ghcr.io

### Limitations

- The checksum file comes from the same release as the tarball, so it guards against corruption rather than a compromised release (the image digest pin in Patterns 1-3 is stronger)
- Network dependency during test runs
- Slower first run (download ~15MB binary)

For production use in this monorepo, prefer Patterns 1-3, which use the digest-pinned official image.

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
