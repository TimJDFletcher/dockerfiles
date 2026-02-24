# yajsv Docker Image

Minimal container for [yajsv](https://github.com/neilpa/yajsv), a JSON Schema validator.

## Usage

```bash
# Validate a JSON file against a schema
docker run --rm -v $(pwd):/data timjdfletcher/yajsv \
  -s /data/schema.json /data/input.json

# Validate multiple files
docker run --rm -v $(pwd):/data timjdfletcher/yajsv \
  -s /data/schema.json /data/*.json

# Validate YAML files
docker run --rm -v $(pwd):/data timjdfletcher/yajsv \
  -s /data/schema.json -r /data/input.yaml

# Show version
docker run --rm timjdfletcher/yajsv -v
```

## Options

| Flag | Purpose |
|------|---------|
| `-s <schema>` | Schema file to validate against |
| `-r` | Treat input as YAML instead of JSON |
| `-q` | Quiet mode (only output errors) |
| `-v` | Show version |

## Image Size

This image uses a multi-stage build with a `scratch` base, resulting in an extremely small image (~5MB) containing only the statically-linked binary.

## Build

```bash
./run build
```

## Test

```bash
./run test
```

Tests use [goss](https://github.com/goss-org/goss) via a test runner container. Both positive and negative validation cases are tested:

| File | Expected |
|------|----------|
| `valid.json`, `valid2.json` | Pass validation |
| `invalid-missing-required.json` | Fail — missing `age` |
| `invalid-wrong-type.json` | Fail — `age` is string |
| `invalid-extra-property.json` | Fail — undeclared `nickname` |

## Release

```bash
git tag yajsv-v<version>
./run release
```
