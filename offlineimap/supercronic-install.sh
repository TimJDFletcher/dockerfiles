#!/bin/bash
set -eu -o pipefail

VERSION=v0.1.9

amd64(){
  export SUPERCRONIC=supercronic-linux-amd64
  export SUPERCRONIC_SHA1SUM=5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85
}

arm(){
  export SUPERCRONIC=supercronic-linux-arm
  export SUPERCRONIC_SHA1SUM=47481c3341bc3a1ae91a728e0cc63c8e6d3791ad
}
arm64(){
  export SUPERCRONIC=supercronic-linux-arm64
  export SUPERCRONIC_SHA1SUM=e2714c43e7781bf1579c85aa61259245f56dbba1
}

_install()
{
  cd /tmp
  curl -fsSLO https://github.com/aptible/supercronic/releases/download/${VERSION}/${SUPERCRONIC}
  echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c -
  chmod +x "$SUPERCRONIC"
  mv "$SUPERCRONIC" /usr/local/bin/supercronic
}

case "${TARGETPLATFORM}" in
  linux/arm64)
    arm64
    ;;
  linux/arm/v7|linux/arm/v6)
    arm
    ;;
  linux/amd64)
    amd64
    ;;
  *)
    echo TARGETPLATFORM not set, bailing log
    exit 1
    ;;
esac

_install