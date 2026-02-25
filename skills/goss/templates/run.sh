#!/bin/bash
# Goss Container Testing - Run Script Template
# Copy this to your project as ./run and customize IMAGE_NAME
set -eu -o pipefail

# === CUSTOMIZE THESE ===
IMAGE_NAME="myorg/myimage"
IMAGE_TAG="tmp"
# === END CUSTOMIZE ===

GOSS_VERSION="v0.4.9"

log() {
  echo "==> $*"
}

_ensure_goss_volume() {
  # Create volume if it doesn't exist
  if ! docker volume inspect goss-bin >/dev/null 2>&1; then
    log "Creating goss-bin volume..."
    docker volume create goss-bin

    # Set permissions for curlimages/curl user (uid 101:102)
    # This allows downloading without running as root
    docker run --rm -v goss-bin:/target alpine:latest chown 101:102 /target
  fi

  # Download goss binary if not present
  if ! docker run --rm -v goss-bin:/goss-bin:ro alpine:latest test -f /goss-bin/goss; then
    log "Downloading goss ${GOSS_VERSION}..."
    docker run --rm \
      -v goss-bin:/target \
      --entrypoint sh \
      curlimages/curl:latest \
      -c "curl -fsSL https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss-linux-amd64 -o /target/goss && chmod 755 /target/goss"
  fi
}

build() {
  log "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
  docker build --tag "${IMAGE_NAME}:${IMAGE_TAG}" .
}

test() {
  build
  _ensure_goss_volume

  log "Running goss validation tests..."
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "$(pwd)/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}

# Alternative test function for scratch/distroless containers
test_scratch() {
  build
  _ensure_goss_volume

  log "Extracting binary from scratch container..."
  mkdir -p .tmp
  trap "rm -rf .tmp" EXIT

  local tmp_container
  tmp_container=$(docker create "${IMAGE_NAME}:${IMAGE_TAG}")
  docker cp "${tmp_container}:/app" ".tmp/app"  # Adjust binary path
  docker rm "${tmp_container}" >/dev/null
  chmod 755 ".tmp/app"

  log "Running goss tests in external container..."
  docker run --rm \
    -v goss-bin:/goss-bin:ro \
    -v "$(pwd)/.tmp/app:/usr/local/bin/app:ro" \
    -v "$(pwd)/goss/tests:/goss:ro" \
    debian:trixie-slim \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}

clean() {
  log "Cleaning up..."
  docker image rm "${IMAGE_NAME}:${IMAGE_TAG}" || true
  docker image rm "${IMAGE_NAME}:latest" || true
}

usage() {
  cat <<EOF
Usage: ./run [COMMAND]

Commands:
  build    Build the Docker image
  test     Build and run goss tests
  clean    Remove local images
EOF
}

case ${1:-} in
  build) build ;;
  test)  test ;;
  clean) clean ;;
  *)     usage ;;
esac
