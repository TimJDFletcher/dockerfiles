FROM debian:buster-20200224-slim

ARG TARGETPLATFORM

ENV OFFLINEIMAP_VERSION="7.2.3+dfsg1-1" \
    CURL_VERSION="7.64.0-4+deb10u1" \
    CA_CERTIFICATES_VERSION="20190110" \
    PROCPS_VERSION="2:3.3.15-2 "

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY supercronic-install.sh /usr/local/bin/supercronic-install.sh
RUN chmod 0755 /usr/local/bin/supercronic-install.sh

RUN apt-get update \
 && apt-get --no-install-recommends --yes install \
    offlineimap="${OFFLINEIMAP_VERSION}" \
    ca-certificates="${CA_CERTIFICATES_VERSION}" \
    curl="${CURL_VERSION}" \
    procps=${PROCPS_VERSION} \
 && useradd --home-dir /email --no-create-home offlineimap \
 && rm -rf /var/cache/apt

RUN /usr/local/bin/supercronic-install.sh

COPY crontab /etc/crontab
COPY entrypoint /entrypoint

RUN chmod 0755 /entrypoint

USER offlineimap

ENTRYPOINT ["/entrypoint"]
