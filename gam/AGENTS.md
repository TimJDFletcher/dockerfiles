# GAM Agent Documentation

This document provides technical context for AI agents working on the `gam` Docker packaging project.

## 1. Project Goal

Provide a Docker container packaging [GAM](https://github.com/GAM-team/GAM) (Google Apps Manager), a command line tool for Google Workspace administration. The pip package is `gam7` and the CLI command is `gam`.

## 2. Core Components

| Component | Value |
|-----------|-------|
| Base Image | `python:3.13.12-slim` |
| Package | `gam7==7.34.6` |
| CLI Command | `gam` |
| Docker Hub | `timjdfletcher/gam` |

## 3. Build Args

| ARG | Default | Purpose |
|-----|---------|---------|
| `PYTHON_VERSION` | `3.13.12-slim` | Python base image tag |
| `GAM_VERSION` | `7.34.6` | gam7 pip package version |

## 4. File Structure

| File | Purpose |
|------|---------|
| `Dockerfile` | Installs pinned `gam7` via pip on slim Python image |
| `entrypoint` | Routes CLI flags to `gam`, or `exec`s arbitrary commands |
| `run` | Build/test/clean/release helper script |
| `goss/tests/` | goss test definitions |
| `README.md` | User-facing documentation |

## 5. Entrypoint Behaviour

The entrypoint script checks the first argument:
- If it's a valid command: `exec`s the arguments directly (allows running `bash`, etc.)
- Otherwise: passes all arguments to `gam`

The default `CMD` is `--help`, so running the container with no arguments prints GAM help.

## 6. Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image `timjdfletcher/gam:tmp` |
| `test` | Build and run goss tests |
| `clean` | Remove local images and buildx cache |
| `start` | Run with `~/.gam` bind-mounted |
| `release` | Test, build multi-arch, push to Docker Hub |

## 7. Testing

Uses the shared `goss-bin` Docker volume pattern. Tests validate:

| Test | Purpose | Duration |
|------|---------|----------|
| `/entrypoint` file | Exists with 0755 permissions | <1s |
| `gam version` | Shows correct version (7.34.06) | ~1s |
| `gam --help` | Help output works | ~1s |
| `pip show gam7` | Exact package version installed | <1s |
| `python --version` | Entrypoint exec path works | <1s |
| `gam checkconnection` | Network to 40+ Google APIs | ~25s |

Total test time: ~28 seconds (network test dominates).

### Offline Commands

These GAM commands work without credentials:
- `gam version` — Show version info
- `gam --help` — Show help
- `gam checkconnection` — Test network connectivity to Google APIs

Most other commands require OAuth2 credentials.

## 8. Tagging & Release Process

Tags follow the `gam-v<version>` convention (e.g. `gam-v0.2`). The `./run release` command:
1. Runs tests
2. Finds the latest `gam-*` tag
3. Checks out that tag (detached HEAD)
4. Builds and pushes multi-platform images to Docker Hub

After release, switch back to `main` with `git checkout main`.

## 9. Dependency Updates

| Dependency | Check URL |
|------------|-----------|
| Python base | https://hub.docker.com/_/python/tags?name=3.13 |
| gam7 | https://pypi.org/project/gam7/ |

Update `PYTHON_VERSION` and `GAM_VERSION` ARGs in Dockerfile, update tests, run `./run test`.

## 10. Authentication to Google Workspace

GAM requires OAuth2 credentials to interact with Google Workspace APIs. These are never baked into the image.

### Required Credential Files

| File                   | Purpose                                      |
|------------------------|----------------------------------------------|
| `oauth2.txt`           | OAuth2 client credentials for admin access   |
| `oauth2service.json`   | Service account key for domain-wide delegation |
| `client_secrets.json`  | OAuth2 client ID and secret                  |

### Initial Setup

`gam create project` and `gam oauth create` require interactive browser-based OAuth consent flows. Run these locally or in an interactive container session first.

### Runtime Credential Injection

Three approaches, in order of simplicity:

1.  **Bind-mount config directory:** `-v /path/to/gam-config:/root/.gam`
2.  **Mount individual files read-only with tmpfs:** Use `--tmpfs /root/.gam:size=1m` plus `:ro` bind mounts for each credential file. Prevents cached tokens persisting on disk.
3.  **GAMCFGDIR environment variable:** `-e GAMCFGDIR=/gam-config -v /path/to/config:/gam-config:ro` for flexible config location.

## 11. Upstream Details

| Item | Value |
|------|-------|
| Repository | https://github.com/GAM-team/GAM |
| PyPI Package | `gam7` |
| Python Requirement | >=3.10 |
| Key Dependencies | google-api-python-client, google-auth, cryptography, lxml |
| License | Apache 2.0 |

## 12. Pitfalls & Gotchas

- **Version display**: GAM displays version `7.34.6` as `7.34.06` (leading zero in patch)
- **Warnings on stderr**: `gam version` prints RequestsDependencyWarning and config warnings to stderr before the version output — filter with `2>/dev/null` when parsing
- **Config initialization**: GAM creates `~/.gam/` directory and config file on first run, even for `--help`
- **Network test duration**: `gam checkconnection` takes ~25 seconds (tests 40+ Google API endpoints)
- **Entrypoint logic**: First argument is checked with `command -v` — if it's a valid command (like `python`, `bash`), it's exec'd directly; otherwise passed to `gam`
