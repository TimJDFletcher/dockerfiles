FROM debian:buster-20191014-slim

ENV OFFLINEIMAP_VERSION="7.2.3+dfsg1-1"

ENV SUPERCRONIC_VERSION=v0.1.9 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/$SUPERCRONIC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get --no-install-recommends --yes install \
    offlineimap="${OFFLINEIMAP_VERSION}" ca-certificates curl \
 && useradd --home-dir /email --no-create-home offlineimap \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
 && apt-get purge --yes curl \
 && apt-get autoremove --yes \
 && rm -rf /var/cache/apt

COPY crontab /etc/crontab
COPY entrypoint /entrypoint

RUN chmod 0755 /entrypoint

USER offlineimap

ENTRYPOINT ["/entrypoint"]
