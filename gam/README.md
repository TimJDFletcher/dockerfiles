# GAM Docker Image

Docker packaging for [GAM](https://github.com/GAM-team/GAM), a command line tool for Google Workspace administration.

## Usage

```bash
docker run --rm timjdfletcher/gam:latest --help
```

## Build

```bash
./run build
```

## Release

Tags follow the `gam-v<version>` convention. To release:

```bash
git tag -s gam-v0.2 -m "GAM v0.2"
git push origin gam-v0.2
./run release
```

## Authentication

GAM requires OAuth2 credentials to interact with Google Workspace APIs. Initial setup (`gam create project`, `gam oauth create`) must be done interactively since it requires browser-based OAuth consent flows. Never bake credentials into the image.

### Bind-mount a config directory (simplest)

Set up GAM on your host first, then mount the config directory:

```bash
docker run --rm -v /path/to/gam-config:/root/.gam timjdfletcher/gam:latest info domain
```

### Service account only (best for automation)

Mount only the required credential files as read-only, using tmpfs to avoid persisting cached tokens:

```bash
docker run --rm \
  --tmpfs /root/.gam:size=1m \
  -v /path/to/oauth2service.json:/root/.gam/oauth2service.json:ro \
  -v /path/to/client_secrets.json:/root/.gam/client_secrets.json:ro \
  -v /path/to/oauth2.txt:/root/.gam/oauth2.txt:ro \
  timjdfletcher/gam:latest info domain
```

### Using GAMCFGDIR (most flexible)

GAM respects the `GAMCFGDIR` environment variable to locate its config:

```bash
docker run --rm \
  -e GAMCFGDIR=/gam-config \
  -v /path/to/gam-config:/gam-config:ro \
  timjdfletcher/gam:latest info domain
```
