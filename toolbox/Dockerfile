ARG DEBIAN_VERSION="bookworm-20260223-slim"
FROM debian:${DEBIAN_VERSION}

ARG TOOLS

RUN apt-get update && \
    apt-get install --no-install-recommends --yes ${TOOLS} && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]

