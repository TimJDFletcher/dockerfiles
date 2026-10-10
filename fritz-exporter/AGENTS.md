# fritz-exporter Agent Documentation

Our build of [pdreker/fritz_exporter](https://github.com/pdreker/fritz_exporter), the Prometheus exporter for FRITZ! devices, from the fork `TimJDFletcher/fritz_exporter`. The fork carries one patch: when TR-064 answers 0 for both optical levels (FRITZ!Box 5530 Fiber, FRITZ!OS 8.25), read them from the web UI page `data.lua?page=fiberStats` and report them under the existing `fritz_fiber_*` metric names. Tracked in tim/estate#117.

## Core Components

| Component | Value |
|-----------|-------|
| Source | `FRITZ_EXPORTER_REPO` at `FRITZ_EXPORTER_COMMIT` (ARG, commit SHA; the fork's tag `fritzexporter-v<upstream>-estate.<n>`) |
| Base image | `python:${PYTHON_VERSION}` (ARG), the same as upstream's Dockerfile |
| Build | Multi-stage: wheel built with `python -m build`, installed into a clean base |
| User | `65534:65534` (the Monitoring stack runs it as that uid) |
| Port | 9787 |
| Entrypoint | `python -m fritzexporter` |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image `timjdfletcher/fritz-exporter:tmp` |
| `test` | Build, then run the image tests |
| `clean` | Remove images and prune builder |
| `release` | Test, then multi-arch build/push of the newest `fritz-exporter-v*` tag |

## Testing

Direct container tests, no goss:

| Test | Expects |
|------|---------|
| Installed version | `importlib.metadata` reports `EXPECTED_VERSION` (in `run`) |
| `--version` | exits 0 |
| uid | `id -u` is 65534 |
| Patch present | `fritzexporter.fritz_fiber` imports |
| No credentials | exit 1 and "Required env variables missing" |

## Pitfalls

- Upstream's `--version` prints `develop` (it looks up the distribution under the wrong name), so the version test reads package metadata.
- `data.lua` pages are not a published interface: a FRITZ!OS update can rename `fiberStats`, and the levels read 0 again.
- The levels change once an hour whatever the scrape interval; the fallback adds one web request per scrape.
- Password: use `FRITZ_PASSWORD_FILE` with a file readable by uid 65534; never `FRITZ_PASSWORD` in a compose file.

## Dependency Update Workflow

1. Upstream releases: in the fork, rebase `fiber-webui-levels` onto the new `fritzexporter-v*` tag, run `uv run pytest` and `uv run ruff check`, push, and tag `fritzexporter-v<version>-estate.1`.
2. Set `FRITZ_EXPORTER_COMMIT` (and the comment above it) to the new tag's commit SHA, and `EXPECTED_VERSION` in `run`.
3. Check the Python tag upstream's Dockerfile uses (https://github.com/pdreker/fritz_exporter/blob/main/Dockerfile) and update `PYTHON_VERSION`.
4. `./run test`, then `git tag fritz-exporter-v<version> && ./run release` (owner only).
