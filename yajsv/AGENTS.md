# yajsv Agent Documentation

Minimal container for [yajsv](https://github.com/neilpa/yajsv), a JSON Schema validator written in Go.

## Core Components

| Component | Value |
|-----------|-------|
| Build Image | `golang:1.25` |
| Final Image | `scratch` (no OS, just the binary) |
| Binary | Statically linked via `-ldflags '-linkmode external -extldflags "-static"'` |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/yajsv:tmp` |
| `clean` | Remove images and prune builder |
| `release` | Multi-arch build/push to Docker Hub |

## Usage

```bash
# Validate JSON against schema
docker run --rm -v $(pwd):/data timjdfletcher/yajsv -s /data/schema.json /data/input.json

# Validate multiple files
docker run --rm -v $(pwd):/data timjdfletcher/yajsv -s /data/schema.json /data/*.json
```

## Architecture

Multi-stage build:
1. **Builder stage** — Compiles yajsv with static linking
2. **Final stage** — Copies only the binary to a `scratch` image

Result is an extremely small image (~5MB) with no shell or OS.

## Testing (`goss`)

Since yajsv uses a `scratch` image (no OS), tests extract the binary and run goss in a separate container.

### Test Architecture

```
./run test
├── Build yajsv scratch image
├── Ensure goss v0.4.9 in goss-bin volume (downloaded from GitHub)
├── Extract /yajsv binary to .tmp/
├── Run debian:trixie-slim container with:
│   ├── goss-bin volume mounted (provides /goss-bin/goss)
│   ├── yajsv binary mounted to /usr/local/bin/
│   ├── goss test files mounted
│   └── test-data/ mounted
└── Clean up .tmp/
```

Uses the shared `goss-bin` volume with a pinned goss version downloaded from GitHub.

### Test Cases

| Test | Expected | Purpose |
|------|----------|---------|
| `yajsv -v` | exit 0 | Binary runs |
| `valid.json` | exit 0, "pass" | Valid JSON accepted |
| `valid2.json` | exit 0, "pass" | Minimal valid JSON accepted |
| Multiple valid files | exit 0 | Batch validation works |
| `invalid-missing-required.json` | exit 1, "age is required" | Missing field rejected |
| `invalid-wrong-type.json` | exit 1, "Invalid type" | Type mismatch rejected |
| `invalid-extra-property.json` | exit 1, "Additional property" | Extra fields rejected |

### Test Files

- `goss/tests/goss-validation-tests.yaml` — Goss test definitions
- `test-data/schema.json` — JSON Schema (draft-07) defining a Person object
- `test-data/valid*.json` — Valid documents
- `test-data/invalid-*.json` — Invalid documents for negative testing

Run tests with `./run test`.

### Pitfalls

**macOS temp directories aren't accessible in Docker.** The test extracts the binary to `.tmp/` in the project directory (which is shared with Docker) rather than `/var/folders/`.

**yajsv binary needs glibc.** Despite the `-static` flag, the binary has glibc dependencies (DNS), so tests run in debian-based goss image not alpine.

**Goss downloaded on first run.** Tests download goss `v0.4.9` from GitHub to a shared `goss-bin` volume if not present.

## Build Args

| Arg | Default | Purpose |
|-----|---------|---------|
| `GO_VERSION` | `1.25` | Go builder image version |
| `YAJSV_VERSION` | `v1.4.1` | yajsv release tag |

Version is injected via ldflags (`-X main.version`) because the upstream source embeds a dev version string.

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| yajsv | https://github.com/neilpa/yajsv/releases |
| Go | https://hub.docker.com/_/golang |

After updating `YAJSV_VERSION`, also update:
- `run` script: `YAJSV_VERSION` variable
- `goss/tests/goss-validation-tests.yaml`: version check
