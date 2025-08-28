FROM debian:stable-slim
ARG TOOLS

RUN apt-get update && \
    apt-get install --no-install-recommends --yes ${TOOLS} && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]

