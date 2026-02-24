ARG DEBIAN_VERSION="trixie-slim"
FROM debian:${DEBIAN_VERSION}

ARG GOSS_VER="v0.4.9"

RUN apt-get update && \
    apt-get install --no-install-recommends --yes curl ca-certificates && \
    ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/goss-org/goss/releases/download/${GOSS_VER}/goss-linux-${ARCH}" \
      -o /usr/local/bin/goss && \
    chmod 755 /usr/local/bin/goss && \
    apt-get purge --yes curl && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["goss"]
CMD ["--help"]
