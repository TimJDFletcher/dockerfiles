# yajsv Agent Documentation

Minimal container for [yajsv](https://github.com/neilpa/yajsv), a JSON Schema validator written in Go.

## Core Components

| Component | Value |
|-----------|-------|
| Build Image | `golang:1.26` |
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

## Testing

Tests run the container image directly (no goss needed for scratch images). This is simpler and validates actual container behavior.

### Test Cases

| Test | Expected | Purpose |
|------|----------|---------|
| Default CMD | `v1.4.1` | Version correct |
| `valid.json` | exit 0, "pass" | Valid JSON accepted |
| `valid2.json` | exit 0, "pass" | Minimal valid JSON accepted |
| Multiple valid files | "pass" x2 | Batch validation works |
| `invalid-missing-required.json` | "age is required" | Missing field rejected |
| `invalid-wrong-type.json` | "Invalid type" | Type mismatch rejected |
| `invalid-extra-property.json` | "Additional property" | Extra fields rejected |

### Test Files

- `test-data/schema.json` — JSON Schema (draft-07) defining a Person object
- `test-data/valid*.json` — Valid documents
- `test-data/invalid-*.json` — Invalid documents for negative testing

Run tests with `./run test`.

## Build Args

| Arg | Default | Purpose |
|-----|---------|---------|
| `GO_VERSION` | `1.26` | Go builder image version |
| `YAJSV_VERSION` | `v1.4.1` | yajsv release tag |

Version is injected via ldflags (`-X main.version`) because the upstream source embeds a dev version string.

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| yajsv | https://github.com/neilpa/yajsv/releases |
| Go | https://hub.docker.com/_/golang |

After updating `YAJSV_VERSION`, also update `run` script: `YAJSV_VERSION` variable.
