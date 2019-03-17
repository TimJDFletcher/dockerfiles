FROM debian:stable-20190228

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends --yes \
    install offlineimap ca-certificates curl

ENV SUPERCRONIC_VERSION=v0.1.8 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=be43e64c45acd6ec4fce5831e03759c89676a0ea

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/$SUPERCRONIC

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

RUN useradd --home-dir /email --no-create-home offlineimap 

ADD crontab /etc/crontab

ADD entrypoint /entrypoint

RUN chmod 755 /entrypoint

USER offlineimap

ENTRYPOINT ["/entrypoint"]
