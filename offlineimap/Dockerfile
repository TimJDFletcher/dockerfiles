ARG DEBIAN_VERSION="trixie-20260223-slim"
ARG SUPERCRONIC_VERSION="v0.2.43"

FROM debian:${DEBIAN_VERSION}

ARG TARGETPLATFORM
ARG SUPERCRONIC_VERSION

RUN apt-get update \
 && apt-get --no-install-recommends --yes install \
    offlineimap \
    ca-certificates \
    curl \
    procps \
 && useradd --home-dir /email --no-create-home offlineimap \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    ARCH=$(uname -m); \
    case "${ARCH}" in \
      x86_64)  SUPERCRONIC_ARCH="amd64" ;; \
      aarch64) SUPERCRONIC_ARCH="arm64" ;; \
      armv7l)  SUPERCRONIC_ARCH="arm" ;; \
      *)       echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-${SUPERCRONIC_ARCH}" \
      -o /usr/local/bin/supercronic; \
    chmod 755 /usr/local/bin/supercronic

COPY --chmod=0644 crontab /etc/crontab
COPY --chmod=0755 entrypoint /entrypoint

USER offlineimap

ENTRYPOINT ["/entrypoint"]
