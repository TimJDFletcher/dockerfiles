# Dockerfiles Monorepo — Agent Context

This file provides context for AI agents working on this repository. Every project has its own `<project>/AGENTS.md` with specific details.

## Repository Overview

A monorepo of Docker container projects for personal infrastructure. Each subdirectory is a self-contained project with its own `Dockerfile` and typically a `./run` script.

## Project Index

| Project | Purpose | Status | Notes |
|---------|---------|--------|-------|
| `samba-timemachine` | macOS Time Machine backup server via Samba | Active | Most mature; has goss tests, AGENTS.md |
| `gam` | Google Workspace CLI (GAM) container | Active | Has AGENTS.md |
| `checkov` | Bridgecrew Checkov security scanner | Maintained | Simple pip install; unpinned versions |
| `toolbox` | Generic Debian toolbox container | Maintained | Build-arg driven; customizable tools |
| `yajsv` | JSON schema validator (Go) | Active | Multi-stage scratch build (~5MB); has tests |
| `offlineimap` | Email sync with supercronic | Stale | Pinned to bullseye-20220125; needs upgrade |
| `postfix` | SMTP relay | Stale | Pinned to bullseye-20200224; needs upgrade |
| `tcpdump` | Network debugging | Minimal | One-liner; has AGENTS.md with test proposal |
| `ssh-audit` | SSH security auditing | Active | Full test suite with hardened/weak sshd; has AGENTS.md, README |
| `goss` | Goss testing framework | Active | Shared test image for other projects |
| `media` | Media server stack | Reference | Compose-only; third-party images |

## Known Issues & Tech Debt

### Medium Priority
- **Stale base images**: `offlineimap` and `postfix` use Debian bullseye from 2020-2022; should upgrade to bookworm or trixie
- **checkov Dockerfile style**: Uses `ADD` instead of `COPY`, separate `chmod` instead of `COPY --chmod=`

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

Three projects have test suites: `samba-timemachine`, `ssh-audit`, and `yajsv`.

**samba-timemachine** tests three phases:
1. **Build-time tests**: Validate image structure
2. **Healthcheck tests**: Validate running container
3. **Live integration tests**: Validate user-facing behavior

**ssh-audit** tests both positive and negative cases:
1. **Build-time tests**: Validate binary install and version
2. **Integration tests**: Audit a hardened sshd (must pass with exit 0) and a weak sshd (must fail with exit >= 2)

**yajsv** uses the shared `goss` image (since main image is `scratch`):
1. **Positive tests**: Valid JSON files pass schema validation
2. **Negative tests**: Invalid files (missing fields, wrong types, extra properties) are rejected

**goss** is a shared testing image used by other projects. Build it first with `cd goss && ./run build`.

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
