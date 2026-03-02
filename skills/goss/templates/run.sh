#!/bin/bash
# Goss Container Testing - Run Script Template
# Copy this to your project as ./run and customize IMAGE_NAME
set -eu -o pipefail

# === CUSTOMIZE THESE ===
IMAGE_NAME="myorg/myimage"
IMAGE_TAG="tmp"
GOSS_IMAGE="timjdfletcher/goss"
# === END CUSTOMIZE ===

log() {
  echo "==> $*"
}

_ensure_goss() {
  local goss_dir="${PWD}/.goss-bin"
  if [ ! -x "${goss_dir}/goss" ]; then
    log "Extracting goss from ${GOSS_IMAGE}:${IMAGE_TAG}..."
    mkdir -p "${goss_dir}"
    docker rm goss-extract 2>/dev/null || true
    docker create --name goss-extract "${GOSS_IMAGE}:${IMAGE_TAG}" >/dev/null
    docker cp goss-extract:/goss "${goss_dir}/goss"
    docker rm goss-extract >/dev/null
  fi
}

build() {
  log "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
  docker build --tag "${IMAGE_NAME}:${IMAGE_TAG}" .
}

test() {
  build
  _ensure_goss

  log "Running goss validation tests..."
  docker run --rm \
    -v "${PWD}/.goss-bin:/goss-bin:ro" \
    -v "${PWD}/goss/tests:/goss:ro" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}

# Alternative test function for scratch/distroless containers
test_scratch() {
  build
  _ensure_goss

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
    -v "${PWD}/.goss-bin:/goss-bin:ro" \
    -v "${PWD}/.tmp/app:/usr/local/bin/app:ro" \
    -v "${PWD}/goss/tests:/goss:ro" \
    debian:trixie-slim \
    /goss-bin/goss --gossfile /goss/goss-dockerfile-tests.yaml validate

  log "All tests passed!"
}

clean() {
  log "Cleaning up..."
  docker image rm "${IMAGE_NAME}:${IMAGE_TAG}" || true
  docker image rm "${IMAGE_NAME}:latest" || true
  rm -rf .goss-bin .tmp
}

usage() {
  cat <<EOF
Usage: ./run [COMMAND]

Commands:
  build    Build the Docker image
  test     Build and run goss tests
  clean    Remove local images and extracted goss binary
EOF
}

case ${1:-} in
  build) build ;;
  test)  test ;;
  clean) clean ;;
  *)     usage ;;
esac
