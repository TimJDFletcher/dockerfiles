FROM debian:bullseye-20200224-slim

ENV POSTFIX_VERSION="3.5.0-1"

RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        postfix="${POSTFIX_VERSION}" \
        iproute2 && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 25/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]