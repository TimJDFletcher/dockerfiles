# Samba-TimeMachine Agent Documentation

Docker container running Samba configured to emulate an Apple Time Capsule for macOS Time Machine backups.

## Core Components

* **Base Image:** `debian:trixie-slim`
* **Core Service:** `samba` (from `trixie-backports`)
* **Templating:** `envsubst` (from `gettext-base`) generates config files from templates
* **Testing:** `goss` for build-time validation, runtime health checks, and live integration tests
* **Orchestration:** `./run` shell script and Docker Compose

## Environment Variables

| Variable | Default | Used In |
|---|---|---|
| `USER` | `timemachine` | `entrypoint`, `smb.conf.tmpl` |
| `PASS` | `password` | `entrypoint` (`smbpasswd`) |
| `PUID` | `999` | `entrypoint` (`useradd`, `chown`) |
| `PGID` | `999` | `entrypoint` (`groupadd`, `chown`) |
| `LOG_LEVEL` | `1` | `smb.conf.tmpl` |
| `BACKUPDIR` | `/backups` | `entrypoint`, `smb.conf.tmpl` |
| `FORCE_PERMISSIONS_RESET` | `false` | `entrypoint` (recursive `chown`) |

## Entrypoint Initialization Order

Order is critical — `configureSAMBA` must run before `createUser` (see Pitfalls).

1. **`checkBackupDir`** — Verifies `${BACKUPDIR}` exists and warns if not a mountpoint.
2. **`cleanupLegacyFiles`** — Removes obsolete `.com.apple.TimeMachine.quota.plist`.
3. **`configureSAMBA`** — Generates `/etc/samba/smb.conf` from template via `envsubst`.
4. **`createUser`** — Creates group/user with `PGID`/`PUID`, sets Samba password via `smbpasswd`.
5. **`configureBackupDir`** — Sets ownership, creates Apple metadata files, copies `backup-check.sh`.
6. **`startSMB`** — Runs `smbd` in the foreground as PID 1.

## Developer Workflow (`./run`)

| Command | Description |
|---|---|
| `build` | Build local image tagged `timjdfletcher/samba-timemachine:tmp` |
| `up` | Build and start via `docker compose up` |
| `down` | Stop and remove containers |
| `exec` | Start (if needed) and shell into container |
| `test` | Full goss test suite (sets `PUID=1234`, `USER=testuser`, etc. in a subshell) |
| `trivy` | Build and run Trivy security scan |
| `release` | Test + Trivy + multi-arch build/push to Docker Hub |
| `clean` | Remove images and prune builder |
| `copyToTestHost` | Build and copy image to test host via SSH |
| `timemachineLogs` | Stream macOS Time Machine logs |

Release tags follow SemVer: `timemachine-v<VERSION>` (e.g., `timemachine-v1.2.3`).

## Testing (`goss`)

Three test suites, each validating a different phase:

* **`goss-dockerfile-tests.yaml`** (build-time) — Templates and entrypoint exist with correct permissions; `smb.conf` does *not* exist yet; required packages installed, build deps purged.
* **`goss-healthcheck-tests.yaml`** (runtime) — `smbd` running, port `10445` listening, `testparm` passes, `smbclient` loopback integration test (mkdir/ls/rmdir), disk usage < 95%.
* **`goss-live-tests.yaml`** (integration) — User/group created with correct UID/GID, `smb.conf` contains expected values, `smbclient` write test.
* **`goss-permissions-tests.yaml`** (permissions) — Validates `FORCE_PERMISSIONS_RESET` feature by checking file ownership against `EXPECTED_OWNER`/`EXPECTED_GROUP` env vars.

## Pitfalls & Gotchas

**Samba listens on port `10445` inside the container** (`smb ports = 10445` in `samba.conf.tmpl`). The compose file `ports.target` is the container-side port and must match. `ports.published` is the host-side port. All goss tests run inside the container via `docker compose exec` and connect to `127.0.0.1:10445` directly, so they **do not validate Docker port mapping**.

**Entrypoint ordering: `configureSAMBA` before `createUser`.** `smbpasswd` reads `smb.conf` to locate the passdb backend. If `smb.conf` doesn't exist yet, `smbpasswd` fails with a cryptic error.

**`COPY goss/` busts the apt layer cache.** It appears before `RUN apt-get install` in the Dockerfile. Any change to goss test files invalidates the package install cache. This is a trade-off: the goss-installer script must run during that `RUN` step.

**`backup-check.sh` is for the host, not the container.** It requires `curl` (purged from the image at build time). The entrypoint copies it into `${BACKUPDIR}/` so it can be run from the host or a host cron job.

**`docker-compose-autoheal.yml` is a standalone production example.** It is not used by `./run` commands and may have divergent configuration from `docker-compose.yml`.

**`USER` env var collides with the standard shell variable.** The `./run test` command exports `USER=testuser` in a subshell to avoid clobbering the parent shell's login user.

## Updating Dependencies

Three pinned versions in the Dockerfile `ARG` block need periodic checking:

| Dependency | ARG | Where to check latest |
|---|---|---|
| Debian base image | `DEBIAN_VERSION` | Docker Hub tags matching `trixie-*-slim` — use the API: `https://hub.docker.com/v2/repositories/library/debian/tags?name=trixie&page_size=20&ordering=last_updated` |
| Samba | `SAMBA_VERSION` | `https://packages.debian.org/trixie-backports/samba` — the version string is the Debian package version (e.g. `2:4.23.5+dfsg-1~bpo13+1`) |
| Goss | `GOSS_VER` | `https://github.com/goss-org/goss/releases/latest` |

The Samba version must match what's available in `trixie-backports`. If the version is bumped and the old version is removed from the repo, the build will fail. The `smbclient` package is pinned to the same version as `samba` — always update both together.

After updating, run `./run test` to validate the build and all integration tests still pass.
