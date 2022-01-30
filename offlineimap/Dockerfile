FROM debian:bullseye-20220125-slim

ARG TARGETPLATFORM

ENV OFFLINEIMAP_VERSION="7.3.3+dfsg1-1+0.0~git20210225.1e7ef9e+dfsg-4" \
    CURL_VERSION="7.74.0-1.3+deb11u1" \
    CA_CERTIFICATES_VERSION="20210119" \
    PROCPS_VERSION="2:3.3.17-5"

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
