# Samba-TimeMachine Agent Documentation

Docker container running Samba configured to emulate an Apple Time Capsule for macOS Time Machine backups.

## Core Components

* **Base Image:** `debian:trixie-slim`
* **Core Service:** `samba` (from `trixie-backports`)
* **Templating:** `envsubst` (from `gettext-base`) generates config files from templates
* **Testing:** `goss` (built from source via `../goss` project) for build-time validation, runtime health checks, and live integration tests
* **Orchestration:** `./run` shell script and Docker Compose

## Prerequisites

The `goss` image is built automatically if missing. When you run `./run build` or `./run test`, the script checks for `timjdfletcher/goss:tmp` and builds it from `../goss` if needed.

To build manually:

```bash
cd ../goss && ./run build
```

The samba-timemachine Dockerfile uses `COPY --from=timjdfletcher/goss:tmp` to get the goss binary.

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
| `METRICS_FILE` | unset (off) | `entrypoint` (renders `postexec`, writes initial metrics) |
| `METRICS_POSTEXEC` | set by `entrypoint` | `smb.conf.tmpl` (the `postexec` line, or empty) |

## Entrypoint Initialization Order

Order is critical — `configureSAMBA` must run before `createUser` (see Pitfalls).

1. **`checkBackupDir`** — Verifies `${BACKUPDIR}` exists and warns if not a mountpoint.
2. **`cleanupLegacyFiles`** — Removes obsolete `.com.apple.TimeMachine.quota.plist`.
3. **`configureMetrics`** — Sets `METRICS_POSTEXEC` to the `postexec` line when `METRICS_FILE` is set, else empty.
4. **`configureSAMBA`** — Generates `/etc/samba/smb.conf` from template via `envsubst`.
5. **`createUser`** — Creates group/user with `PGID`/`PUID`, sets Samba password via `smbpasswd`, generates `/run/samba/credentials` for smbclient.
6. **`configureBackupDir`** — Sets ownership, creates Apple metadata files, copies `backup-check.sh`.
7. **`writeInitialMetrics`** — If `METRICS_FILE` is set, runs `backup-metrics.sh` once as `PUID`:`PGID` (via `setpriv`); warns and carries on if it can't write.
8. **`startSMB`** — Runs `smbd` in the foreground as PID 1.

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

`./run test` runs three phases: default permissions, `FORCE_PERMISSIONS_RESET=true`, and backup metrics (`METRICS_FILE` set). Every phase mounts the `samba-timemachine_metrics` volume via `docker-compose.metrics.yml`. Phase 3 also connects over SMB from the container's own (non-loopback) address to create a sparsebundle, waits for the rewrite, and parses the file with `promtool` (`PROMTOOL_IMAGE` in `run`, pinned by tag and digest) for an empty share and for one bundle.

The goss suites:

* **`goss-dockerfile-tests.yaml`** (build-time) — Templates and entrypoint exist with correct permissions; `smb.conf` does *not* exist yet; required packages installed, build deps purged.
* **`goss-healthcheck-tests.yaml`** (runtime) — `smbd` running, port `10445` listening, `testparm` passes, `smbclient` loopback integration test (mkdir/ls/rmdir), disk usage < 95%.
* **`goss-live-tests.yaml`** (integration) — User/group created with correct UID/GID, `smb.conf` contains expected values, `smbclient` write test.
* **`goss-permissions-tests.yaml`** (permissions) — Validates `FORCE_PERMISSIONS_RESET` feature by checking file ownership against `EXPECTED_OWNER`/`EXPECTED_GROUP` env vars.
* **`goss-metrics-disabled-tests.yaml`** (phase 1) — No `postexec` in `smb.conf`; a connect/disconnect leaves `/metrics` empty.
* **`goss-metrics-tests.yaml`** (phase 3) — `postexec` rendered and backgrounded; file written at start (mode `0644`, owned by `USER`, success `1`, zero bundles); unreadable backup dir writes success `0`, keeps last-success, no bundle values; loopback clients don't write.

## Pitfalls & Gotchas

**Samba listens on port `10445`** (`smb ports = 10445` in `samba.conf.tmpl`). This non-standard port allows the container to run alongside an existing Samba server on port 445. The compose file maps `10445:10445`. Goss tests run inside the container and connect to `127.0.0.1:10445` directly.

**Entrypoint ordering: `configureSAMBA` before `createUser`.** `smbpasswd` reads `smb.conf` to locate the passdb backend. If `smb.conf` doesn't exist yet, `smbpasswd` fails with a cryptic error.

**Goss is built from source.** The `goss` project builds goss with patched Go dependencies to fix CVEs. The samba-timemachine Dockerfile uses `COPY --from=timjdfletcher/goss:tmp` to get the binary. Build the goss project first before building samba-timemachine.

**`backup-check.sh` is for the host, not the container.** It requires `curl` (not installed in the image). The entrypoint copies it into `${BACKUPDIR}/` so it can be run from the host or a host cron job.

**Backup metrics (`scripts/backup-metrics.sh`).** Usage: `backup-metrics.sh <output-file> <backup-dir> [client-address]`. Metrics and caveats are documented in `README.md` → "Backup Metrics". Things that bit during implementation:

* `postexec` runs as the connecting user, so the output directory must be writable by `PUID`:`PGID`.
* smbd waits for `postexec` to finish before completing the disconnect, **and runs it without a shell**: it splits the line into arguments itself, so `>/dev/null &` on the bare command becomes literal arguments and the script runs in the foreground. The rendered line is `/bin/sh -c "… &"`. Check with a deliberately slow script and time `smbclient`; a plain `sleep 3 … &` looks fast only because `sleep` errors on the extra arguments.
* The healthcheck (and goss tests) connect over `127.0.0.1` every minute. `%I` is passed to the script, which exits for loopback addresses so it doesn't rewalk every sparsebundle each minute. Tests that need a rewrite connect via `$(hostname -i)`.
* Writes go to `mktemp "<file>.XXXXXX"` in the same directory, then `chmod 0644` and `mv`, so concurrent runs are safe.

**`systemd-unit.service`** is a production deployment example for running via systemd.

**`USER` env var collides with the standard shell variable.** The `./run test` command exports `USER=testuser` in a subshell to avoid clobbering the parent shell's login user.

**Credentials file for smbclient.** The entrypoint generates `/run/samba/credentials` (mode 600) so goss tests can authenticate without exposing the password in `/proc/cmdline`. Tests use `smbclient -A /run/samba/credentials` instead of `-U user%pass`.

## Updating Dependencies

Two pinned versions in the Dockerfile `ARG` block need periodic checking:

| Dependency | ARG | Where to check latest |
|---|---|---|
| Debian base image | `DEBIAN_VERSION` | Docker Hub tags matching `trixie-*-slim` — use the API: `https://hub.docker.com/v2/repositories/library/debian/tags?name=trixie&page_size=20&ordering=last_updated` |
| Samba | `SAMBA_VERSION` | `https://packages.debian.org/trixie-backports/samba` — the version string is the Debian package version (e.g. `2:4.23.6+dfsg-2~bpo13+1`) |

The Samba version must match what's available in `trixie-backports`. If the version is bumped and the old version is removed from the repo, the build will fail. The `smbclient` package is pinned to the same version as `samba` — always update both together.

**Goss updates:** See the `../goss/AGENTS.md` for updating goss. Goss is built from source with patched dependencies in a separate project.

After updating, run `./run test` to validate the build and all integration tests still pass.

## macOS Native Containers

Tested with macOS 26.3 and the `container` CLI (via Homebrew). The native container system works well for building and running this image.

### What Works

| Feature | Status | Notes |
|---------|--------|-------|
| Build image | ✓ | Requires `--build-arg DEBIAN_VERSION=...` (ARG before FROM not auto-expanded) |
| Multi-arch builds | ✓ | `--platform linux/arm64 --platform linux/amd64` |
| Run container | ✓ | Full support for `-e`, `-p`, `-v` flags |
| Volume mounts | ✓ | Named volumes work correctly |
| Port mapping | ✓ | |
| Exec into container | ✓ | |
| Healthcheck tests | ✓ | All 27 tests pass |
| Live integration tests | ✓ | All 43 tests pass |

### What Doesn't Work

**`container-compose` (v0.9.0)** is not ready for this project:
- Fails to parse docker-compose.yml extended volume syntax
- Tries to pull images from registry even when they exist locally
- Limited compose file compatibility

### Example Commands

```bash
# Build (must pass DEBIAN_VERSION explicitly)
container build -t timjdfletcher/samba-timemachine:test \
  --build-arg DEBIAN_VERSION=trixie-20260824-slim .

# Run
container run -d --name samba-tm \
  -e PUID=1000 -e PGID=1000 \
  -e USER=timemachine -e PASS=secret \
  -p 10445:10445 \
  -v backups:/backups \
  timjdfletcher/samba-timemachine:test

# Test
container exec samba-tm /goss/goss --gossfile /goss/tests/goss-healthcheck-tests.yaml validate
```
