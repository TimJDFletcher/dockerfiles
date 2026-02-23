# GAM Agent Documentation

This document provides technical context for AI agents working on the `gam` Docker packaging project.

## 1. Project Goal

Provide a Docker container packaging [GAM](https://github.com/GAM-team/GAM) (Google Apps Manager), a command line tool for Google Workspace administration. The pip package is `gam7` and the CLI command is `gam`.

## 2. Core Components

*   **Base Image:** `python:3`
*   **Package:** `gam7` installed via pip
*   **CLI Command:** `gam`
*   **Docker Hub:** `timjdfletcher/gam`

## 3. File Structure

| File         | Purpose                                                                 |
|--------------|-------------------------------------------------------------------------|
| `Dockerfile` | Installs `gam7` via pip on `python:3`, sets up entrypoint               |
| `entrypoint` | Routes CLI flags to `gam`, or `exec`s arbitrary commands                |
| `run`        | Build/clean/release helper script using Docker buildx                   |
| `README.md`  | User-facing documentation with usage and authentication guidance        |

## 4. Entrypoint Behaviour

The entrypoint script checks the first argument:
*   If empty or starts with `-`: passes all arguments to `gam`
*   Otherwise: `exec`s the arguments directly (allows running arbitrary commands like `bash`)

The default `CMD` is `--help`, so running the container with no arguments prints GAM help.

## 5. Developer Workflow (`./run` script)

*   **`./run build`**: Builds a local image tagged `timjdfletcher/gam:tmp` using buildx.
*   **`./run clean`**: Removes local images and buildx cache.
*   **`./run release`**: Checks out the latest `gam-*` git tag, builds multi-arch images (`linux/amd64`, `linux/arm64`), and pushes both the versioned tag and `latest` to Docker Hub.

## 6. Tagging & Release Process

Tags follow the `gam-v<version>` convention (e.g. `gam-v0.1`). The `./run release` command:
1.  Finds the latest `gam-*` tag via `git tag | grep ^gam | sort -n | tail -n 1`
2.  Checks out that tag (detached HEAD)
3.  Builds and pushes multi-platform images to Docker Hub

After release, switch back to `main` with `git checkout main`.

## 7. Authentication to Google Workspace

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

## 8. Upstream Details

*   **Repository:** https://github.com/GAM-team/GAM
*   **PyPI Package:** `gam7`
*   **Python Requirement:** >=3.10
*   **Key Dependencies:** google-api-python-client, google-auth, cryptography, lxml
*   **License:** Apache 2.0
