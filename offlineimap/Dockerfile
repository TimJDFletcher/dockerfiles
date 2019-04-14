FROM debian:stable-20190326

ENV OFFLINEIMAP_VERSION="7.0.12+dfsg1-2"

ENV SUPERCRONIC_VERSION=v0.1.8 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=be43e64c45acd6ec4fce5831e03759c89676a0ea

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/$SUPERCRONIC

RUN apt-get update \
 && apt-get --no-install-recommends --yes install \
    offlineimap="7.0.12+dfsg1-2" ca-certificates curl \
 && useradd --home-dir /email --no-create-home offlineimap \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
 && apt-get purge --yes curl \
 && apt-get autoremove --yes \
 && rm -rf /var/cache/apt

ADD crontab /etc/crontab

ADD entrypoint /entrypoint

RUN chmod 755 /entrypoint

USER offlineimap

ENTRYPOINT ["/entrypoint"]
