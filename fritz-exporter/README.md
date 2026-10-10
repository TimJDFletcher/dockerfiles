# fritz-exporter Docker Image

[pdreker/fritz_exporter](https://github.com/pdreker/fritz_exporter) built from the fork [TimJDFletcher/fritz_exporter](https://github.com/TimJDFletcher/fritz_exporter), which adds a fallback for FRITZ!Box Fiber models whose TR-064 interface reports 0 for both optical levels: the levels are read from the web UI instead.

## Usage

```bash
docker run --rm -p 9787:9787 \
  -e FRITZ_HOSTNAME=fritz.box -e FRITZ_USERNAME=exporter \
  -v /path/to/password:/pw:ro -e FRITZ_PASSWORD_FILE=/pw \
  timjdfletcher/fritz-exporter
```

The container runs as uid 65534: the password file must be readable by it. Configuration is the upstream environment variables (see upstream's documentation).

## Build

```bash
./run build
```

## Test

```bash
./run test
```

## Release

```bash
git tag fritz-exporter-v<version>
./run release
```
