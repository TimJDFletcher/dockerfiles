# SPF-Flattener Agent Documentation

Docker container for [spf-flattener](https://github.com/letsencrypt/spf-flattener), a tool that flattens SPF records to avoid the 10 DNS lookup limit.

## Purpose

SPF records can include other domains (via `include:` mechanism), but DNS resolvers impose a 10 lookup limit. This tool "flattens" SPF records by resolving all includes and replacing them with the actual IP addresses.

## Usage

```bash
# Dry run (default) - just output the flattened record
docker run --rm timjdfletcher/spf-flattener --domain example.com

# Verbose output
docker run --rm timjdfletcher/spf-flattener --domain example.com --verbose

# With initial SPF to compare
docker run --rm timjdfletcher/spf-flattener --domain example.com \
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
| `GO_VERSION` | `1.24` | Go version for compilation |
| `SPF_FLATTENER_VERSION` | `main` | Git branch/tag to build from |

## Developer Workflow

| Command | Description |
|---------|-------------|
| `./run build` | Build local image |
| `./run test` | Build and run tests against real domains |
| `./run trivy` | Build and run Trivy security scan |
| `./run clean` | Remove images |
| `./run release` | Test + scan + multi-arch push to Docker Hub |

## Notes

- The container includes CA certificates for HTTPS/DNS-over-HTTPS
- Tests run against real domains (google.com, letsencrypt.org) in dryrun mode
- The binary is statically compiled and runs in a scratch container
