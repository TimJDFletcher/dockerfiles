#!/bin/bash
# Goss Container Testing - Run Script Template (GitHub Download Pattern)
# Use this when the ghcr.io/goss-org/goss image can't be pulled (e.g. registry access is blocked)
# Copy this to your project as ./run and customize IMAGE_NAME
set -eu -o pipefail

# === CUSTOMIZE THESE ===
IMAGE_NAME="myorg/myimage"
IMAGE_TAG="tmp"
GOSS_VERSION="v0.4.10"
# === END CUSTOMIZE ===

log() {
  echo "==> $*"
}

_get_goss_arch() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64)  echo "x86_64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    armv7l)  echo "armv6" ;;
    armv6l)  echo "armv6" ;;
    *)       echo "x86_64" ;;
  esac
}

_ensure_goss_volume() {
  local goss_arch
  goss_arch=$(_get_goss_arch)

  # Create volume if missing
  if ! docker volume inspect goss-bin >/dev/null 2>&1; then
    log "Creating goss-bin volume..."
    docker volume create goss-bin

    # Set permissions for curlimages/curl user (uid 101:102)
    # This allows downloading without running as root
    docker run --rm -v goss-bin:/target alpine:latest chown 101:102 /target
  fi

  # Download goss if missing or wrong version. Releases ship tarballs plus a
  # SHA256SUMS file; the tarball is verified before extracting.
  local ver="${GOSS_VERSION#v}"
  local base="https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}"
  local archive="goss_${ver}_linux_${goss_arch}.tar.gz"
  log "Ensuring goss ${GOSS_VERSION} in volume..."
  docker run --rm \
    -v goss-bin:/target \
    --entrypoint sh \
    curlimages/curl:latest -c "
      set -e
      if [ -f /target/goss ] && /target/goss --version 2>&1 | grep -q 'version ${ver}\$'; then
        echo 'goss ${GOSS_VERSION} already installed'
      else
        cd /tmp
        curl -fsSLO \"${base}/${archive}\"
        curl -fsSLO \"${base}/goss_${ver}_SHA256SUMS\"
        grep ' ${archive}\$' goss_${ver}_SHA256SUMS | sha256sum -c -
        tar -xzf ${archive} -C /target goss
        chmod 755 /target/goss
        echo 'goss ${GOSS_VERSION} installed'
      fi
    "
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
    -v "${PWD}/goss/tests:/goss:ro" \
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
  rm -rf .tmp
  # Optionally remove goss volume (shared across projects):
  # docker volume rm goss-bin || true
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
