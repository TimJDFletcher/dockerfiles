FROM FROM debian:buster-20200224-slim

ENV POSTFIX_VERSION="3.4.8-0+10debu1"

RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        postfix="${POSTFIX_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 25/tcp

