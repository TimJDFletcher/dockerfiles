# Dockerfiles Monorepo — Agent Context

This file provides context for AI agents working on this repository. Every project has its own `<project>/AGENTS.md` with specific details.

## Repository Overview

A monorepo of Docker container projects for personal infrastructure. Each subdirectory is a self-contained project with its own `Dockerfile` and typically a `./run` script.

## Project Index

| Project | Purpose | Status | Notes |
|---------|---------|--------|-------|
| `samba-timemachine` | macOS Time Machine backup server via Samba | Active | Most mature; has goss tests, AGENTS.md |
| `gam` | Google Workspace CLI (GAM) container | Active | Has AGENTS.md |
| `checkov` | Bridgecrew Checkov security scanner | Active | Pinned versions; has goss tests |
| `toolbox` | Generic Debian toolbox container | Maintained | Build-arg driven; customizable tools |
| `yajsv` | JSON schema validator (Go) | Active | Multi-stage scratch build (~5MB); has tests |
| `offlineimap` | Email sync with supercronic | Active | Debian trixie; has goss tests |
| `postfix` | SMTP relay | Active | Debian trixie; has goss tests |
| `tcpdump` | Network debugging | Active | Debian trixie; has goss + integration tests |
| `ssh-audit` | SSH security auditing | Active | Full test suite with hardened/weak sshd; has AGENTS.md, README |
| `media` | Media server stack | Reference | Compose-only; third-party images |

## Known Issues & Tech Debt

### Low Priority
- Missing `./run` script: `media` (uses docker compose directly)

## Conventions (Quick Reference)

See `.cursorrules` for full details. Key points:

- **`./run` script**: Standard interface (`build`, `clean`, `release`)
- **Tags**: `<project>-v<MAJOR>.<MINOR>.<PATCH>`
- **Base images**: Pin versions via `ARG` (e.g., `ARG DEBIAN_VERSION="trixie-20260202-slim"`)
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

Seven projects have test suites: `samba-timemachine`, `ssh-audit`, `yajsv`, `checkov`, `offlineimap`, `postfix`, and `tcpdump`.

**samba-timemachine** tests three phases:
1. **Build-time tests**: Validate image structure
2. **Healthcheck tests**: Validate running container
3. **Live integration tests**: Validate user-facing behavior

**ssh-audit** tests both positive and negative cases:
1. **Build-time tests**: Validate binary install and version
2. **Integration tests**: Audit a hardened sshd (must pass with exit 0) and a weak sshd (must fail with exit >= 2)

**yajsv** extracts binary and runs goss externally (scratch image has no shell):
1. **Positive tests**: Valid JSON files pass schema validation
2. **Negative tests**: Invalid files (missing fields, wrong types, extra properties) are rejected

**checkov** mounts goss into the Python container:
1. **Direct artifact tests**: Version and help output
2. **Goss tests**: Entrypoint permissions, version match, help output

### Shared goss-bin Volume

All test suites use a shared `goss-bin` Docker volume containing a pinned goss binary downloaded from GitHub. This removes dependencies on pre-built images and ensures version consistency.

```bash
# The _ensure_goss_volume() function in each run script:
# 1. Creates goss-bin volume if missing
# 2. Downloads pinned goss version from GitHub (idempotent)
# 3. Mounts volume read-only into test containers

# For containers with a shell (checkov, ssh-audit):
docker run --rm -v goss-bin:/goss-bin:ro ... /goss-bin/goss validate

# For scratch containers (yajsv):
docker run --rm -v goss-bin:/goss-bin:ro debian:trixie-slim /goss-bin/goss validate
```

The volume persists across test runs. Each project pins `GOSS_VERSION` (currently `v0.4.9`).

When adding tests to other projects, follow these patterns.

## Dependency Update Workflow

1. Check upstream for new versions (see project AGENTS.md for URLs)
2. Update `ARG` in Dockerfile
3. Run `./run test` if available, otherwise `./run build`
4. Tag and release: `git tag <project>-v<VERSION> && ./run release`

## Working With This Repo

- Always `cd` into the project subdirectory before running `./run` commands
- The most complex/interesting project is `samba-timemachine` — use it as a reference
- When in doubt about patterns, check existing implementations in mature projects
