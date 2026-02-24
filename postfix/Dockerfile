ARG DEBIAN_VERSION="trixie-20260223-slim"

FROM debian:${DEBIAN_VERSION}

RUN apt-get update \
 && apt-get --no-install-recommends --yes install \
    postfix \
    iproute2 \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 25/tcp

COPY --chmod=0755 entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]
