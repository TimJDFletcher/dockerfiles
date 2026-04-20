# SPF-Flattener Agent Documentation

Container for [spf-flattener](https://github.com/letsencrypt/spf-flattener), a tool that flattens SPF records to avoid the 10 DNS lookup limit.

**Note**: This project uses **Apple Container** (Apple’s native **`container`** CLI), not Docker, for build, test, and normal runs—primarily because Colima’s DNS mishandles multi-record TXT lookups (see Known Issues below).

### Apple Container service

If `container build` / `container run` fails with XPC errors, *connection invalid*, or prompts to start the system service, start Apple Container first:

```bash
container system start
```

Wait until the service is ready, then use `./run build`, `./run test`, etc. as usual.

## Purpose

SPF records can include other domains (via `include:` mechanism), but DNS resolvers impose a 10 lookup limit. This tool "flattens" SPF records by resolving all includes and replacing them with the actual IP addresses.

## Usage

```bash
# Dry run (default) - just output the flattened record
container run --rm timjdfletcher/spf-flattener --domain example.com

# Debug output
container run --rm timjdfletcher/spf-flattener --domain example.com --logLevel=debug

# With initial SPF to compare
container run --rm timjdfletcher/spf-flattener --domain example.com \
  --initialSPF "v=spf1 include:_spf.google.com ~all"
```

## Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--domain` | Yes | | Root domain to set SPF record for |
| `--initialSPF` | No | "" | Initial SPF record to flatten (if empty, looks up existing) |
| `--verbose` | No | false | Print extra debug lines |
| `--dryrun` | No | true | If false, update existing SPF record |
| `--warn` | No | true | Compare initial and flattened SPF, warn if different |
| `--url` | No* | "" | URL to PATCH updated SPF record |
| `--authEmail` | No* | "" | X-Auth-Email header value |
| `--authKey` | No* | "" | X-Auth-Key header value |

*Required if `--dryrun=false`

## Build Arguments

| ARG | Default | Description |
|-----|---------|-------------|
| `GO_VERSION` | `1.26` | Go version for compilation |
| `SPF_FLATTENER_VERSION` | `main` | Git branch/tag to build from |

## Developer Workflow

Uses Apple’s **`container`** CLI (Apple Container) for all operations in this directory—not `docker` / Colima for the default workflow.

| Command | Description |
|---------|-------------|
| `./run build` | Build local image |
| `./run test` | Build and run tests (including real DNS tests) |
| `./run clean` | Remove images |
| `./run release` | Test + multi-arch build (push manually) |

## Notes

- Uses Apple **`container`** (Apple Container) for proper DNS resolution in tests
- Tests include real SPF flattening against gmail.com
- Built with `golang:alpine` for musl compatibility
- Alpine base image with CA certificates

## Known Issues

### Colima DNS Bug

When running in Docker with colima on macOS, DNS TXT record lookups fail because colima's DNS resolver incorrectly concatenates multiple TXT records into a single string. For example, a domain with 3 separate TXT records:

```
"v=spf1 redirect=_spf.google.com"
"globalsign-smime-dv=CDYX+..."
"yahoo-verification-key=..."
```

Gets returned as one concatenated record:

```
"v=spf1 redirect=_spf.google.comglobalsign-smime-dv=CDYX+...yahoo-verification-key=..."
```

This causes the tool to parse malformed domain names from the SPF record.

**Workarounds**:
- Use Apple **`container`** (`container system start`, then `container run` / `./run test`) instead of Docker with Colima for this project
- Run on Linux or Docker Desktop
- Any non-colima environment with proper DNS resolution

The container and tool work correctly when DNS returns records properly.
