# Dockerfiles Monorepo — Agent Context

This file provides context for AI agents working on this repository. For project-specific details, see `<project>/AGENTS.md` where available.

## Repository Overview

A monorepo of Docker container projects for personal infrastructure. Each subdirectory is a self-contained project with its own `Dockerfile` and typically a `./run` script.

## Project Index

| Project | Purpose | Status | Notes |
|---------|---------|--------|-------|
| `samba-timemachine` | macOS Time Machine backup server via Samba | Active | Most mature; has goss tests, AGENTS.md |
| `gam` | Google Workspace CLI (GAM) container | Active | Has AGENTS.md |
| `checkov` | Bridgecrew Checkov security scanner | Maintained | Simple pip install |
| `toolbox` | Generic Debian toolbox container | Maintained | Build-arg driven |
| `yajsv` | JSON schema validator (Go) | Maintained | Multi-stage scratch build |
| `offlineimap` | Email sync with supercronic | Stale | Pinned to bullseye-20220125 |
| `postfix` | SMTP relay | Stale | Pinned to bullseye-20200224 |
| `tcpdump` | Network debugging | Minimal | One-liner |
| `ssh-audit` | SSH security auditing | Active | Has goss tests, AGENTS.md |
| `media` | Media server stack | Reference | Compose-only, third-party images |

## Known Issues & Tech Debt

### Medium Priority
- **Stale base images**: `offlineimap` and `postfix` use Debian bullseye from 2020-2022; should upgrade to bookworm or trixie
- **checkov Dockerfile style**: Uses `ADD` instead of `COPY`, separate `chmod` instead of `COPY --chmod=`

### Low Priority
- Missing `./run` scripts: `ssh-audit`, `media`
- Missing AGENTS.md: Most projects (only `samba-timemachine` and `gam` have them)

## Conventions (Quick Reference)

See `.cursorrules` for full details. Key points:

- **`./run` script**: Standard interface (`build`, `clean`, `release`)
- **Tags**: `<project>-v<MAJOR>.<MINOR>.<PATCH>`
- **Base images**: Pin versions via `ARG` (e.g., `ARG DEBIAN_VERSION="trixie-20260202-slim"`)
- **Builds**: Purge build deps in same `RUN` layer, use `--no-install-recommends`
- **Multi-arch**: Release builds target `linux/amd64,linux/arm64`

## Testing Philosophy

Only `samba-timemachine` has a test suite. Its approach is exemplary:

1. **Build-time tests** (`goss-dockerfile-tests.yaml`): Validate image structure
2. **Healthcheck tests** (`goss-healthcheck-tests.yaml`): Validate running container
3. **Live integration tests** (`goss-live-tests.yaml`): Validate user-facing behavior

When adding tests to other projects, follow this pattern.

## Dependency Update Workflow

1. Check upstream for new versions (see project AGENTS.md for URLs)
2. Update `ARG` in Dockerfile
3. Run `./run test` if available, otherwise `./run build`
4. Tag and release: `git tag <project>-v<VERSION> && ./run release`

## Working With This Repo

- Always `cd` into the project subdirectory before running `./run` commands
- The most complex/interesting project is `samba-timemachine` — use it as a reference
- When in doubt about patterns, check existing implementations in mature projects
