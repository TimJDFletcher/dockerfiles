FROM debian:stable-slim

RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
	ca-certificates \
    curl \
    dnsutils \
    jq \
    less  \
    lsof \
    net-tools \
    procps \
    strace \
    tcpdump \
    vim \
  && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]