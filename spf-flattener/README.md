# SPF-Flattener

Container for [spf-flattener](https://github.com/letsencrypt/spf-flattener), a tool that flattens SPF records to avoid the 10 DNS lookup limit.

## Why Apple Container CLI?

This project uses Apple's native `container` CLI instead of Docker. When running containers with Docker on macOS via colima, DNS TXT record lookups are broken—multiple TXT records get concatenated into a single string, causing SPF parsing to fail.

Apple's native container runtime handles DNS correctly, making it the recommended option for this tool on macOS.

### Installing Container CLI

```bash
brew install container
```

Requires macOS 26.0 or later with native container support enabled.

## Usage

```bash
# Flatten SPF record (dry run)
container run --rm timjdfletcher/spf-flattener --domain example.com

# Debug output
container run --rm timjdfletcher/spf-flattener --domain example.com --logLevel=debug

# Compare against existing SPF
container run --rm timjdfletcher/spf-flattener --domain example.com \
  --initialSPF "v=spf1 include:_spf.google.com ~all"
```

## Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--domain` | Yes | | Root domain to set SPF record for |
| `--initialSPF` | No | "" | Initial SPF record to flatten |
| `--dryrun` | No | true | If false, update existing SPF record |
| `--warn` | No | true | Compare initial and flattened SPF |
| `--logLevel` | No | "LevelInfo" | debug, info, warn, error |
| `--url` | No* | "" | API URL to PATCH updated SPF record |
| `--authEmail` | No* | "" | X-Auth-Email header value |
| `--authKey` | No* | "" | X-Auth-Key header value |

*Required if `--dryrun=false`

## Building

```bash
./run build    # Build local image
./run test     # Build and run tests
./run clean    # Remove images
```
