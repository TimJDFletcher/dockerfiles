# Dockerfiles Monorepo — Agent Context

This file provides context for AI agents working on this repository. Every project has its own `<project>/AGENTS.md` with specific details.

## Repository Overview

A monorepo of Docker container projects for personal infrastructure. Each subdirectory is a self-contained project with its own `Dockerfile` and typically a `./run` script.

## Project Index

| Project | Purpose | Status | Notes |
|---------|---------|--------|-------|
| `samba-timemachine` | macOS Time Machine backup server via Samba | Active | Most mature; has goss tests, AGENTS.md; embeds goss |
| `gam` | Google Workspace CLI (GAM) container | Active | Pinned versions; has goss tests |
| `checkov` | Bridgecrew Checkov security scanner | Active | Pinned versions; has goss tests |
| `toolbox` | Generic Debian toolbox container | Maintained | Debian trixie; build-arg driven tools |
| `yajsv` | JSON schema validator (Go) | Active | Multi-stage scratch build (~5MB); has tests |
| `offlineimap` | Email sync with supercronic | Active | Debian trixie; has goss tests |
| `postfix` | SMTP relay | Active | Debian trixie; has goss tests |
| `tcpdump` | Network debugging | Active | Debian trixie; has goss + integration tests |
| `ssh-audit` | SSH security auditing | Active | Full test suite with hardened/weak sshd; has AGENTS.md, README |
| `spf-flattener` | SPF record flattening tool | Active | Alpine image; Let's Encrypt tool; requires DNS for testing |
| `media` | Media server stack | Reference | Compose-only; third-party images; has ./run |

## Known Issues & Tech Debt

Open tickets live in the top-level `TODO/` directory (one Markdown file per ticket, with a `Status:` line). All current tickets are for `samba-timemachine`:

- `01` Password visible via `docker inspect`
- `02` Default password baked into image layers
- `03` `.dockerignore` is empty
- `04` External volume requires manual pre-creation
- `05` `backup-check.sh` depends on `curl` but `curl` is purged from the image
- `06` Rootless operation
- `07` Configurable listen port

Check `TODO/` for the current list rather than relying on this summary.

## Conventions (Quick Reference)

See `.cursorrules` for full details. Key points:

- **`./run` script**: Standard interface (`build`, `clean`, `release`)
- **Tags**: `<project>-v<MAJOR>.<MINOR>.<PATCH>`
- **Base images**: Pin versions via `ARG` (e.g., `ARG DEBIAN_VERSION="trixie-20260918-slim"`)
- **Builds**: Purge build deps in same `RUN` layer, use `--no-install-recommends`
- **Multi-arch**: Release builds target `linux/amd64,linux/arm64`

## Testing Philosophy

**Use Test-Driven Development (TDD)** with the red-green-refactor loop. See the [TDD skill](https://github.com/mattpocock/skills/tree/b2039ab896a01ebcc539704f69974f7bcdfb1226/tdd) for detailed guidance.

### Core Principles

1. **Test behavior, not implementation** — Tests verify what users care about (can I connect? can I backup?) not internal function calls
2. **Use public interfaces** — Test through CLI/API, not internal methods
3. **One test at a time** — RED→GREEN for each behavior, never write all tests first (horizontal slicing anti-pattern)
4. **Never refactor while RED** — Get to GREEN first, then refactor

### Workflow

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
REFACTOR: Clean up (tests still pass)
REPEAT: Next behavior
```

### Test Quality Checklist

- [ ] Test describes behavior, not implementation
- [ ] Test uses public interface only
- [ ] Test would survive internal refactor
- [ ] Code is minimal for this test

Eight projects have test suites: `samba-timemachine`, `ssh-audit`, `yajsv`, `checkov`, `offlineimap`, `postfix`, `tcpdump`, and `gam`.

**samba-timemachine** tests three phases:
1. **Build-time tests**: Validate image structure
2. **Healthcheck tests**: Validate running container
3. **Live integration tests**: Validate user-facing behavior

**ssh-audit** tests both positive and negative cases:
1. **Build-time tests**: Validate binary install and version
2. **Integration tests**: Audit a hardened sshd (must pass with exit 0) and a weak sshd (must fail with exit >= 2)

**yajsv** tests the container image directly (no goss needed for scratch images):
1. **Version test**: Default CMD returns correct version
2. **Positive tests**: Valid JSON files pass schema validation
3. **Negative tests**: Invalid files (missing fields, wrong types, extra properties) are rejected with correct error messages

**checkov** mounts goss into the Python container:
1. **Direct artifact tests**: Version and help output
2. **Goss tests**: Entrypoint permissions, version match, help output

**gam** includes network connectivity tests:
1. **Build-time tests**: Version, help, pip package verification
2. **Entrypoint tests**: Verify exec path works (e.g., `python --version`)
3. **Network tests**: `gam checkconnection` validates connectivity to 40+ Google APIs (~25s)

### Goss Distribution

All projects use the official goss image, `ghcr.io/goss-org/goss`, pinned by tag **and** digest (the multi-arch index digest, so both amd64 and arm64 are covered). The binary lives at `/usr/bin/goss` in that image. The pin appears in `samba-timemachine/Dockerfile` and in each CLI project's `run` script.

(Goss used to be built from source in a local `goss` project to patch vulnerable Go dependencies. Upstream `v0.4.10` ships current dependencies, so that project was retired.)

**Pattern 1: Embedded (services with healthcheck)**

Copy goss into the image for build-time validation and runtime healthchecks:

```dockerfile
ARG GOSS_IMAGE="ghcr.io/goss-org/goss:v0.4.10@sha256:8d3924f722a04a660e9e6c2403be0399d737c0187fc065714d26b992286c3f0a"
FROM ${GOSS_IMAGE} AS goss
FROM debian:trixie-slim
COPY --from=goss /usr/bin/goss /goss/goss
```

Used by: `samba-timemachine`

**Pattern 2: External (CLI tools)**

Extract goss at test time and mount it. `_ensure_goss()` pulls the pinned image if needed and re-extracts when the pin changes (tracked in `.goss-bin/.image`). `GOSS_IMAGE` can be overridden from the environment, e.g. to use a mirror:

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

# Mount when testing:
docker run --rm -v "${PWD}/.goss-bin:/goss-bin:ro" ... /goss-bin/goss validate
```

Used by: `gam`, `checkov`, `ssh-audit`, `tcpdump`, `postfix`, `offlineimap`

**Scratch images (yajsv):** Don't use goss. Test the container directly by running it with different inputs and checking outputs/exit codes.

## Security Scanning

Use the `checkov` container to scan Dockerfiles:

```bash
docker run --rm -v "$(pwd):/tf" timjdfletcher/checkov:tmp \
  --directory /tf --framework dockerfile --compact --quiet
```

### Acceptable Findings

Some checkov findings are acceptable for this repo:

| Check | Finding | Why It's OK |
|-------|---------|-------------|
| CKV_DOCKER_3 | No USER instruction | CLI tools often need root (tcpdump, postfix) or handle users at runtime (gam, samba-timemachine) |
| CKV_DOCKER_2 | No HEALTHCHECK | Most containers are CLI tools, not long-running services. Only `samba-timemachine` needs HEALTHCHECK |

### Required Practices

- No secrets committed (no `.env`, credentials, keys, PEM files)
- Use `COPY` not `ADD` (except for URLs, which we avoid)
- Pin all versions via `ARG`
- Clean up apt lists: `rm -rf /var/lib/apt/lists/*`
- Use `pip install --no-cache-dir`
- Avoid running as root when downloading from the internet

## Dependency Update Workflow

1. Check upstream for new versions (see project AGENTS.md for URLs)
   - **Goss:** check https://github.com/goss-org/goss/releases, resolve the new tag's index digest (e.g. `docker buildx imagetools inspect ghcr.io/goss-org/goss:<tag>`), then update every `GOSS_IMAGE` pin (`grep -rn ghcr.io/goss-org/goss`) and `GOSS_VER` in `samba-timemachine/Dockerfile`
2. Update `ARG` in Dockerfile
3. Run `./run test` if available, otherwise `./run build`
4. Tag and release: `git tag <project>-v<VERSION> && ./run release`

## macOS Native Containers

The macOS native `container` CLI (Homebrew) works for building, running, and testing images. Tested on macOS 26.3.

| Feature | Status | Notes |
|---------|--------|-------|
| Build | ✓ | Pass `--build-arg` for ARG before FROM |
| Multi-arch | ✓ | `--platform linux/arm64 --platform linux/amd64` |
| Run/exec/volumes/ports | ✓ | Same flags as Docker |
| Goss testing | ✓ | Mount goss-bin volume, use `--entrypoint /goss-bin/goss` |
| container-compose | ✗ | v0.9.0 has limited compose file support |

### Testing with Native Containers

All 8 projects with tests were validated using native containers:

| Project | Tests | Notes |
|---------|-------|-------|
| samba-timemachine | 70 pass | Healthcheck + live tests |
| yajsv | 7 pass | Direct container tests (no goss needed) |
| gam | 12 pass | Includes network connectivity tests |
| checkov | 7 pass | |
| ssh-audit | 4 pass | Build-time only (integration needs compose) |
| tcpdump | 5 pass | |
| postfix | 8 pass | |
| offlineimap | 12 pass | |

**Key differences from Docker:**
- `--entrypoint ""` doesn't work; use `--entrypoint /path/to/binary` instead
- Shared volumes work the same way
- No `docker cp` equivalent; for scratch images, test the container directly

See `samba-timemachine/AGENTS.md` for detailed findings.

## Working With This Repo

- Always `cd` into the project subdirectory before running `./run` commands
- The most complex/interesting project is `samba-timemachine` — use it as a reference
- When in doubt about patterns, check existing implementations in mature projects
