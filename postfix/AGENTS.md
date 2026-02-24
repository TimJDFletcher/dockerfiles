# postfix Agent Documentation

Container for [Postfix](http://www.postfix.org/) SMTP relay server.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `debian:bullseye-20200224-slim` (STALE) |
| Packages | `postfix`, `iproute2` |

## Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `POSTFIX_VERSION` | `3.5.0-1` | Pinned postfix version |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image |
| `test` | Build and run rspec tests |
| `push` | Build, test, tag with git SHA, push to Docker Hub |
| `release` | Checkout latest tag and multi-arch push |

## Usage

Configure via environment variables or mount config files:

```bash
docker run -d \
  -p 25:25 \
  -v /path/to/main.cf:/etc/postfix/main.cf:ro \
  timjdfletcher/postfix
```

## Known Issues

- **Very stale base image** — Uses Debian bullseye from February 2020; should upgrade to trixie
- **Dockerfile style** — Uses `ADD` instead of `COPY`
- **Ruby tests** — Uses rspec with bundler

## Updating Dependencies

| Dependency | Where to check |
|------------|----------------|
| Debian base | https://hub.docker.com/_/debian |
| postfix | `apt-cache policy postfix` in target Debian version |
