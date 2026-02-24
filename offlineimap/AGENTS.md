# offlineimap Agent Documentation

Container for [OfflineIMAP](https://www.offlineimap.org/), an IMAP synchronization tool, with [supercronic](https://github.com/aptible/supercronic) for scheduled syncs.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:bullseye-20220125-slim` (STALE) |
| Packages | `offlineimap`, `ca-certificates`, `curl`, `procps` |
| Scheduler | `supercronic` (installed via script) |

## Environment Variables

Pinned versions in Dockerfile:

| Variable | Purpose |
|----------|---------|
| `OFFLINEIMAP_VERSION` | OfflineIMAP package version |
| `CURL_VERSION` | curl package version |
| `CA_CERTIFICATES_VERSION` | CA certs version |
| `PROCPS_VERSION` | procps package version |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image |
| `test` | Build and run rspec tests |
| `push` | Multi-arch build/push to Docker Hub |

## Usage

Mount your offlineimap config and maildir:

```bash
docker run -d \
  -v /path/to/offlineimaprc:/home/offlineimap/.offlineimaprc:ro \
  -v /path/to/mail:/email \
  timjdfletcher/offlineimap
```

The container runs `supercronic` with `/etc/crontab` by default.

## Known Issues

- **Stale base image** — Uses Debian bullseye from 2022; should upgrade to trixie
- **Ruby tests** — Uses rspec with bundler; may need `bundle install` first

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| Debian base | https://hub.docker.com/_/debian |
| offlineimap | `apt-cache policy offlineimap` in target Debian version |
| supercronic | https://github.com/aptible/supercronic/releases |
