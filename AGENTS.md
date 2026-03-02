# Dockerfiles Monorepo — Agent Context

This file provides context for AI agents working on this repository. Every project has its own `<project>/AGENTS.md` with specific details.

## Repository Overview

A monorepo of Docker container projects for personal infrastructure. Each subdirectory is a self-contained project with its own `Dockerfile` and typically a `./run` script.

## Project Index

| Project | Purpose | Status | Notes |
|---------|---------|--------|-------|
| `goss` | Goss binary built from source | Active | Scratch image; patches CVEs in Go deps; used by other projects |
| `samba-timemachine` | macOS Time Machine backup server via Samba | Active | Most mature; has goss tests, AGENTS.md; depends on `goss` |
| `gam` | Google Workspace CLI (GAM) container | Active | Pinned versions; has goss tests |
| `checkov` | Bridgecrew Checkov security scanner | Active | Pinned versions; has goss tests |
| `toolbox` | Generic Debian toolbox container | Maintained | Debian trixie; build-arg driven tools |
| `yajsv` | JSON schema validator (Go) | Active | Multi-stage scratch build (~5MB); has tests |
| `offlineimap` | Email sync with supercronic | Active | Debian trixie; has goss tests |
| `postfix` | SMTP relay | Active | Debian trixie; has goss tests |
| `tcpdump` | Network debugging | Active | Debian trixie; has goss + integration tests |
| `ssh-audit` | SSH security auditing | Active | Full test suite with hardened/weak sshd; has AGENTS.md, README |
| `media` | Media server stack | Reference | Compose-only; third-party images; has ./run |

## Known Issues & Tech Debt

No outstanding issues.

## Conventions (Quick Reference)

See `.cursorrules` for full details. Key points:

- **`./run` script**: Standard interface (`build`, `clean`, `release`)
- **Tags**: `<project>-v<MAJOR>.<MINOR>.<PATCH>`
- **Base images**: Pin versions via `ARG` (e.g., `ARG DEBIAN_VERSION="trixie-20260223-slim"`)
- **Builds**: Purge build deps in same `RUN` layer, use `--no-install-recommends`
- **Multi-arch**: Release builds target `linux/amd64,linux/arm64`

## Testing Philosophy

**Use Test-Driven Development (TDD)**: Write tests first, verify they fail, then implement the fix.

Example workflow:
1. Write a test that checks for the expected behavior (e.g., version string)
2. Run the test — it should fail
3. Update the code to make the test pass
4. Run the test — it should pass
5. Commit

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

### Goss Distribution Patterns

There are two patterns for distributing goss to projects:

**Pattern 1: Pre-built goss image (preferred for new projects)**

The `goss` project builds goss from source with patched Go dependencies to fix CVEs. Other Dockerfiles can copy the binary:

```dockerfile
FROM timjdfletcher/goss:latest AS goss
FROM debian:trixie-slim
COPY --from=goss /goss /goss/goss
```

Used by: `samba-timemachine`

**Pattern 2: Shared goss-bin volume (legacy)**

Some test suites use a shared `goss-bin` Docker volume containing a pinned goss binary downloaded from GitHub:

```bash
# Volume creation sets permissions for curlimages/curl user (uid 101):
docker volume create goss-bin
docker run --rm -v goss-bin:/target alpine:latest chown 101:102 /target

# Then curlimages/curl can download without root:
docker run --rm -v goss-bin:/target --entrypoint sh curlimages/curl:latest -c \
  'curl -fsSL <url> -o /target/goss && chmod 755 /target/goss'

# For containers with a shell (checkov, ssh-audit, offlineimap, postfix, tcpdump, gam):
docker run --rm -v goss-bin:/goss-bin:ro ... /goss-bin/goss validate
```

**Security note:** We avoid running as root when downloading from the internet.

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
