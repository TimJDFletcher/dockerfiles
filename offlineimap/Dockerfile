FROM debian:stable-20181011

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends --yes install \
    offlineimap \
    ca-certificates \
    curl

ENV SUPERCRONIC_VERSION=v0.1.6 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=c3b78d342e5413ad39092fd3cfc083a85f5e2b75

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
