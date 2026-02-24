# Goss Docker Image

Docker container for [goss](https://github.com/goss-org/goss), a YAML-based server testing framework.

## Usage

```bash
# Show help
docker run --rm timjdfletcher/goss

# Show version
docker run --rm timjdfletcher/goss --version

# Run tests with mounted gossfile
docker run --rm \
  -v $(pwd)/tests:/tests:ro \
  timjdfletcher/goss \
  --gossfile /tests/goss.yaml validate

# Test with verbose output
docker run --rm \
  -v $(pwd)/tests:/tests:ro \
  timjdfletcher/goss \
  --gossfile /tests/goss.yaml validate --format documentation
```

## Testing Binaries

Mount a binary from another image and test it:

```bash
# Extract binary from scratch image
docker cp $(docker create myimage):/mybinary ./mybinary

# Test it with goss
docker run --rm \
  -v $(pwd)/mybinary:/usr/local/bin/mybinary:ro \
  -v $(pwd)/tests:/tests:ro \
  timjdfletcher/goss \
  --gossfile /tests/goss.yaml validate
```

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
git tag goss-v<version>
./run release
```
