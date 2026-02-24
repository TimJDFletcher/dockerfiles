ARG DEBIAN_VERSION="trixie-20260223-slim"

FROM debian:${DEBIAN_VERSION}

RUN apt-get update \
 && apt-get install --no-install-recommends --yes tcpdump \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["tcpdump"]
CMD ["-i", "eth0", "-p", "-nn"]
