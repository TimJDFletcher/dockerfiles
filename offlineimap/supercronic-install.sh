#!/bin/bash
set -eu -o pipefail

VERSION=v0.1.12

amd64(){
  export SUPERCRONIC=supercronic-linux-amd64
  export SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e
}

arm(){
  export SUPERCRONIC=supercronic-linux-arm
  export SUPERCRONIC_SHA1SUM=d72d3d40065c0188b3f1a0e38fe6fecaa098aad5
}
arm64(){
  export SUPERCRONIC=supercronic-linux-arm64
  export SUPERCRONIC_SHA1SUM=8baba3dd0b0b13552aca179f6ef10d55e5dee28b
}

_install()
{
  curl --cacert /etc/ssl/certs/ca-certificates.crt \
    --fail --silent --show-error --location --output ${SUPERCRONIC} \
    https://github.com/aptible/supercronic/releases/download/${VERSION}/${SUPERCRONIC}
  echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c -
  chmod +x "$SUPERCRONIC"
  mv "$SUPERCRONIC" /usr/local/bin/supercronic
}

case "${TARGETPLATFORM:-linux/amd64}" in
  linux/arm64|linux/arm/v8)
    arm64
    ;;
  linux/arm/v6|linux/arm/v7)
    arm
    ;;
  linux/amd64)
    amd64
    ;;
  *)
    echo "TARGETPLATFORM set to unknown platform ${TARGETPLATFORM}, bailing out"
    exit 1
    ;;
esac

_install