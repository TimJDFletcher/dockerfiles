FROM debian:stable-slim

RUN apt-get update && \
    apt-get install --no-install-recommends --yes
	ca-certificates \
    dnsutils \
    lsof \
    curl \
    jq \
    vim \
    tcpdump \
    strace \
    lsof \
    net-tools \
    procps \
  && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]