# Dockerfiles

A collection of Docker container projects for personal infrastructure.

## Projects

| Project | Description | Docker Hub |
|---------|-------------|------------|
| [samba-timemachine](samba-timemachine/) | macOS Time Machine backup server via Samba | [timjdfletcher/samba-timemachine](https://hub.docker.com/r/timjdfletcher/samba-timemachine) |
| [gam](gam/) | Google Workspace administration CLI | [timjdfletcher/gam](https://hub.docker.com/r/timjdfletcher/gam) |
| [checkov](checkov/) | Infrastructure-as-code security scanner | [timjdfletcher/checkov](https://hub.docker.com/r/timjdfletcher/checkov) |
| [toolbox](toolbox/) | Generic Debian toolbox with configurable packages | [timjdfletcher/toolbox](https://hub.docker.com/r/timjdfletcher/toolbox) |
| [yajsv](yajsv/) | JSON Schema validator (minimal scratch image) | [timjdfletcher/yajsv](https://hub.docker.com/r/timjdfletcher/yajsv) |
| [offlineimap](offlineimap/) | Email synchronization with cron scheduling | [timjdfletcher/offlineimap](https://hub.docker.com/r/timjdfletcher/offlineimap) |
| [postfix](postfix/) | SMTP relay server | [timjdfletcher/postfix](https://hub.docker.com/r/timjdfletcher/postfix) |
| [tcpdump](tcpdump/) | Network packet capture | [timjdfletcher/tcpdump](https://hub.docker.com/r/timjdfletcher/tcpdump) |
| [ssh-audit](ssh-audit/) | SSH server security auditing | — |
| [media](media/) | Media server stack (Compose-only) | — |

## Quick Start

Each project follows a consistent interface via the `./run` script:

```bash
cd <project>
./run build      # Build local image
./run clean      # Remove local images
./run release    # Build multi-arch and push to Docker Hub
```

Some projects have additional commands (e.g., `./run test`, `./run up`). Run `./run` without arguments to see available commands.

## Building & Releasing

Images are tagged following semantic versioning with a project prefix:

```bash
git tag samba-timemachine-v1.2.3
./run release
git push && git push --tags
```

Multi-arch builds target `linux/amd64` and `linux/arm64`.

## Project Highlights

### samba-timemachine

The most complete project in this collection. Provides a Docker container that emulates an Apple Time Capsule for macOS Time Machine backups over SMB.

Features:
- Environment variable configuration (user, password, UID/GID)
- Comprehensive test suite using [goss](https://github.com/goss-org/goss)
- Docker Compose support with health checks
- Multi-arch builds (amd64/arm64)

See [samba-timemachine/README.md](samba-timemachine/README.md) for usage details.

### gam

Containerized [GAM](https://github.com/GAM-team/GAM) for Google Workspace administration. Useful for CI/CD pipelines or systems without Python installed.

See [gam/README.md](gam/README.md) for authentication setup.

### yajsv

A minimal JSON Schema validator built as a scratch image (no OS, just the Go binary). Perfect for CI validation steps.

```bash
docker run --rm -v $(pwd):/data timjdfletcher/yajsv -s /data/schema.json /data/file.json
```

## License

MIT
