# Container Testing with Goss

A reusable testing pattern for Docker containers using [goss](https://github.com/goss-org/goss), a YAML-based server validation tool.

## Overview

This skill provides a consistent approach to testing Docker containers:
- **Shared goss binary** via Docker volume (no goss image dependency)
- **Works with any container** including minimal/scratch images
- **Fast iteration** with cached volume across test runs
- **Version pinned** for reproducibility

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      goss-bin volume                        │
│                    (created once, reused)                   │
│                         /goss-bin/goss                      │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
┌───────────────────────┐           ┌───────────────────────┐
│  Container WITH shell │           │ Container WITHOUT shell│
│  (debian, python, etc)│           │    (scratch, distroless)│
│                       │           │                       │
│  Mount goss-bin:ro    │           │  Extract binary to    │
│  Run /goss-bin/goss   │           │  host, run goss in    │
│  inside container     │           │  separate container   │
└───────────────────────┘           └───────────────────────┘
```

## Setup: Shared goss-bin Volume

Add this function to your `./run` script:

```bash
GOSS_VERSION="v0.4.9"

_get_goss_arch() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    armv7l)  echo "arm" ;;
    armv6l)  echo "arm" ;;
    *)       echo "amd64" ;;
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
    docker run --rm -v goss-bin:/target alpine:latest chown 101:102 /target
  fi

  # Download goss if missing
  if ! docker run --rm -v goss-bin:/goss-bin:ro alpine:latest test -f /goss-bin/goss; then
    log "Downloading goss ${GOSS_VERSION} (${goss_arch})..."
    docker run --rm \
      -v goss-bin:/target \
      --entrypoint sh \
      curlimages/curl:latest \
      -c "curl -fsSL https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss-linux-${goss_arch} -o /target/goss && chmod 755 /target/goss"
  fi
}
```

**Security note:** We avoid running as root when downloading. The volume permissions are set once (using alpine as root) so curl downloads run as non-root (uid 101).

## Pattern 1: Containers WITH Shell

For containers based on debian, alpine, python, etc.

### Test Function

```bash
test() {
  build
  _ensure_goss_volume

  log "Running goss tests..."
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "$(pwd)/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}
```

### Example Test File

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
```

## Pattern 2: Containers WITHOUT Shell (scratch/distroless)

For minimal containers with no shell, extract the binary and test externally.

### Test Function

```bash
test() {
  build
  _ensure_goss_volume

  log "Extracting binary from scratch container..."
  mkdir -p .tmp
  trap "rm -rf .tmp" EXIT

  # Create container (don't run it)
  local tmp_container
  tmp_container=$(docker create "${IMAGE_NAME}:${IMAGE_TAG}")
  
  # Copy binary out
  docker cp "${tmp_container}:/myapp" ".tmp/myapp"
  docker rm "${tmp_container}" >/dev/null
  chmod 755 ".tmp/myapp"

  log "Running goss tests..."
  # Run goss in a container that HAS a shell, with binary mounted
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "$(pwd)/.tmp/myapp:/usr/local/bin/myapp:ro" \
    -v "$(pwd)/goss/tests:/goss:ro" \
    -v "$(pwd)/test-data:/data:ro" \
    debian:trixie-slim \
    /goss-bin/goss --gossfile /goss/goss-validation-tests.yaml validate

  log "All tests passed!"
}
```

### .gitignore

Add to project `.gitignore`:

```
.tmp/
```

## Pattern 3: Integration Tests with Docker Compose

For testing container interactions (e.g., network services).

### docker-compose.yml

```yaml
services:
  app:
    image: myimage:tmp
    build:
      context: .
    volumes:
      - goss-bin:/goss-bin:ro
      - ./goss/tests:/goss/tests:ro
    entrypoint: ["/bin/sh", "-c"]
    command: ["sleep infinity"]

  test-dependency:
    image: some-service:latest
    healthcheck:
      test: ["CMD", "healthcheck-command"]
      interval: 2s
      timeout: 5s
      retries: 10

volumes:
  goss-bin:
    external: true
```

### Test Function

```bash
test() {
  build
  _ensure_goss_volume

  log "Starting test environment..."
  docker compose up -d --wait

  log "Running integration tests..."
  docker compose exec app /goss-bin/goss \
    --gossfile /goss/tests/goss-integration-tests.yaml validate

  log "Cleaning up..."
  docker compose down

  log "All tests passed!"
}
```

## Pattern 4: Embedded Goss for Services (Build-time + Healthcheck + Live Tests)

For long-running services, embed goss in the image and use it for:
1. **Build-time validation** — Run during `docker build`
2. **Docker HEALTHCHECK** — Continuous runtime validation
3. **Live integration tests** — Full service validation via `docker compose exec`

This pattern is used in `samba-timemachine` and is ideal for services that need ongoing health monitoring.

### Dockerfile Structure

```dockerfile
ARG GOSS_VERSION="v0.4.9"
ARG GOSS_DST="/goss"

# Copy goss installer first (cache-friendly)
COPY goss/goss-installer ${GOSS_DST}/goss-installer

RUN apt-get update && apt-get install -y curl ca-certificates myservice && \
    # Install goss binary
    sh ${GOSS_DST}/goss-installer && \
    # Cleanup
    apt-get purge -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy tests after apt install (changes don't bust cache)
COPY goss/tests/ ${GOSS_DST}/tests/

COPY entrypoint /entrypoint

# Build-time validation
RUN ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate

# Runtime healthcheck
HEALTHCHECK --interval=1m --timeout=10s \
  CMD ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-healthcheck-tests.yaml validate || exit 1

ENTRYPOINT ["/entrypoint"]
```

### goss-installer Script

Create `goss/goss-installer`:

```bash
#!/bin/sh
set -eu

GOSS_VER="${GOSS_VER:-v0.4.9}"
GOSS_DST="${GOSS_DST:-/goss}"

ARCH=$(uname -m)
case "${ARCH}" in
  x86_64)  GOSS_ARCH="amd64" ;;
  aarch64) GOSS_ARCH="arm64" ;;
  armv7l)  GOSS_ARCH="arm" ;;
  *)       GOSS_ARCH="amd64" ;;
esac

curl -fsSL "https://github.com/goss-org/goss/releases/download/${GOSS_VER}/goss-linux-${GOSS_ARCH}" \
  -o "${GOSS_DST}/goss"
chmod 755 "${GOSS_DST}/goss"
```

### Test File Types

| File | Purpose | When Run |
|------|---------|----------|
| `goss-dockerfile-tests.yaml` | Validate image structure | Build time (`RUN goss validate`) |
| `goss-healthcheck-tests.yaml` | Validate running service | Docker HEALTHCHECK (continuous) |
| `goss-live-tests.yaml` | Full integration tests | `docker compose exec` (manual/CI) |

### Build-time Tests (goss-dockerfile-tests.yaml)

Validate image structure before the entrypoint runs:

```yaml
file:
  /entrypoint:
    exists: true
    mode: "0755"

  # Config should NOT exist yet (created by entrypoint)
  /etc/myservice/config:
    exists: false

package:
  myservice:
    installed: true
  # Build tools should be purged
  curl:
    installed: false

command:
  myservice --version:
    exit-status: 0
    stdout:
      - "1.0.0"
```

### Healthcheck Tests (goss-healthcheck-tests.yaml)

Validate the running service (used by Docker HEALTHCHECK):

```yaml
# Use template variables from environment
file:
  {{.Env.DATA_DIR}}:
    exists: true
    mode: "0755"

  /etc/myservice/config:
    exists: true
    contents:
      - "listen_port = {{.Env.PORT}}"

port:
  tcp:{{.Env.PORT}}:
    listening: true
    ip:
      - 0.0.0.0

process:
  myservice:
    running: true

mount:
  {{.Env.DATA_DIR}}:
    exists: true
    usage:
      lt: 95  # Fail if disk >95% full

command:
  # Service-specific health check
  myservice_health_check:
    exec: "curl -sf http://localhost:{{.Env.PORT}}/health"
    exit-status: 0
    timeout: 5000
```

### Live Integration Tests (goss-live-tests.yaml)

Full end-to-end validation run manually or in CI:

```yaml
# Everything from healthcheck, plus...

user:
  {{.Env.APP_USER}}:
    exists: true
    uid: {{.Env.PUID}}
    gid: {{.Env.PGID}}

group:
  {{.Env.APP_USER}}:
    exists: true
    gid: {{.Env.PGID}}

command:
  # Integration test: full workflow
  integration_test:
    exec: "myservice test-connection --user {{.Env.APP_USER}}"
    exit-status: 0
    stdout:
      - "Connection successful"
    timeout: 30000
```

### Test Runner Script

```bash
GOSS_DST="/goss"
CONTAINER_NAME="myservice"

wait_for_health() {
  log "Waiting for container to become healthy..."
  for _ in {1..30}; do
    if docker compose ps --format json | grep -q '"Health":"healthy"'; then
      log "Container is healthy!"
      return 0
    fi
    sleep 1
  done
  log "Timeout waiting for container health."
  return 1
}

test() {
  build
  
  log "Starting service..."
  docker compose up --detach --remove-orphans
  
  wait_for_health
  
  log "Running live integration tests..."
  docker compose exec "${CONTAINER_NAME}" \
    ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-live-tests.yaml validate
  
  log "All tests passed!"
  docker compose down
}
```

### Multi-Phase Testing

Test different configurations by varying environment variables:

```bash
test() {
  build
  
  # Phase 1: Default configuration
  log "Phase 1: Testing default config..."
  export APP_MODE="default"
  docker compose up -d
  wait_for_health
  docker compose exec myservice /goss/goss --gossfile /goss/tests/goss-live-tests.yaml validate
  docker compose down
  
  # Phase 2: Alternative configuration
  log "Phase 2: Testing strict mode..."
  export APP_MODE="strict"
  docker compose up -d
  wait_for_health
  docker compose exec -e EXPECTED_BEHAVIOR="strict" myservice \
    /goss/goss --gossfile /goss/tests/goss-mode-tests.yaml validate
  docker compose down
  
  log "All phases passed!"
}
```

## Pattern 5: Build-time Tests with Volume (No Embedded Goss)

For images where you don't want goss embedded, but still want build-time validation.

### Approach

1. Build the image
2. Run a test container with goss mounted
3. Execute tests against the built artifacts

```bash
test() {
  build
  _ensure_goss_volume

  log "Running build-time validation..."
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "$(pwd)/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "Starting service for integration tests..."
  docker compose up -d --wait

  log "Running integration tests..."
  docker compose exec -T "${CONTAINER_NAME}" \
    /goss-bin/goss --gossfile /goss/tests/goss-live-tests.yaml validate

  docker compose down
  log "All tests passed!"
}
```

### docker-compose.yml with goss volume

```yaml
services:
  myservice:
    image: myimage:tmp
    build:
      context: .
    volumes:
      - goss-bin:/goss-bin:ro
      - ./goss/tests:/goss/tests:ro
    environment:
      - APP_USER=testuser
      - PORT=8080

volumes:
  goss-bin:
    external: true
```

## Test File Organization

```
project/
├── Dockerfile
├── run
├── .gitignore          # Include .tmp/
└── goss/
    └── tests/
        ├── goss-dockerfile-tests.yaml    # Build-time validation
        ├── goss-integration-tests.yaml   # Runtime/service tests
        └── goss-validation-tests.yaml    # Functional tests
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

## TDD Workflow

1. **Write test first** — Define expected behavior in goss YAML
2. **Run test** — Verify it fails (red)
3. **Implement fix** — Update Dockerfile/code
4. **Run test** — Verify it passes (green)
5. **Commit** — Include both test and fix

## Complete ./run Script Template

```bash
#!/bin/bash
set -eu -o pipefail

IMAGE_NAME="myorg/myimage"
IMAGE_TAG="tmp"
GOSS_VERSION="v0.4.9"

log() {
  echo "==> $*"
}

_get_goss_arch() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    armv7l)  echo "arm" ;;
    armv6l)  echo "arm" ;;
    *)       echo "amd64" ;;
  esac
}

_ensure_goss_volume() {
  local goss_arch
  goss_arch=$(_get_goss_arch)

  if ! docker volume inspect goss-bin >/dev/null 2>&1; then
    log "Creating goss-bin volume..."
    docker volume create goss-bin
    docker run --rm -v goss-bin:/target alpine:latest chown 101:102 /target
  fi

  if ! docker run --rm -v goss-bin:/goss-bin:ro alpine:latest test -f /goss-bin/goss; then
    log "Downloading goss ${GOSS_VERSION} (${goss_arch})..."
    docker run --rm \
      -v goss-bin:/target \
      --entrypoint sh \
      curlimages/curl:latest \
      -c "curl -fsSL https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss-linux-${goss_arch} -o /target/goss && chmod 755 /target/goss"
  fi
}

build() {
  docker build --tag "${IMAGE_NAME}:${IMAGE_TAG}" .
}

test() {
  build
  _ensure_goss_volume

  log "Running goss tests..."
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "$(pwd)/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}

clean() {
  docker image rm "${IMAGE_NAME}:${IMAGE_TAG}" || true
}

case ${1:-} in
  build) build ;;
  test)  test ;;
  clean) clean ;;
  *)     echo "Usage: ./run [build|test|clean]" ;;
esac
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `goss: not found` | Run `_ensure_goss_volume` or check volume mount |
| Permission denied on goss | Volume permissions not set; recreate with `docker volume rm goss-bin` |
| Tests pass locally, fail in CI | Ensure `goss-bin` volume created in CI, or download fresh each run |
| Scratch container: `exec: not found` | Use Pattern 2 (extract binary, test externally) |
| Slow tests | Goss binary is cached in volume; first run downloads |

## References

- [goss documentation](https://github.com/goss-org/goss)
- [goss manual](https://goss.rocks/)
- [dgoss (Docker wrapper)](https://github.com/goss-org/goss/tree/master/extras/dgoss)
