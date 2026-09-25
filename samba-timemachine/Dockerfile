# Official goss release image, pinned by digest (multi-arch index)
ARG GOSS_IMAGE="ghcr.io/goss-org/goss:v0.4.10@sha256:8d3924f722a04a660e9e6c2403be0399d737c0187fc065714d26b992286c3f0a"
ARG DEBIAN_VERSION="trixie-20260824-slim"

FROM ${GOSS_IMAGE} AS goss

FROM debian:${DEBIAN_VERSION}

# Arguments
ARG SAMBA_VERSION="2:4.24.5+dfsg-1~bpo13+1"
ARG GOSS_VER="0.4.10"
ARG GOSS_DST="/goss"
ARG BACKUPDIR="/backups"
ARG DOCS="docs/Container.md"

# Environment Variables
ENV USER="timemachine" \
    PASS="password" \
    PUID="999" \
    PGID="999" \
    LOG_LEVEL="1" \
    FORCE_PERMISSIONS_RESET="false" \
    BACKUPDIR=${BACKUPDIR} \
    GOSS_VER=${GOSS_VER} \
    GOSS_DST=${GOSS_DST}

# Setup Volume
VOLUME ${BACKUPDIR}

# Copy goss binary from the official image (no curl needed!)
COPY --from=goss /usr/bin/goss ${GOSS_DST}/goss

# Install Dependencies & Samba
RUN echo 'deb http://deb.debian.org/debian trixie-backports main' > /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get --no-install-recommends --yes install \
        gettext-base \
    && \
    apt-get --no-install-recommends --yes install -t trixie-backports \
        samba="${SAMBA_VERSION}" \
        smbclient="${SAMBA_VERSION}" \
    && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/* /etc/samba/smb.conf

# Copy goss tests (changes here won't bust the apt cache above)
COPY goss/tests/ ${GOSS_DST}/tests/

# Configuration & Scripts
RUN mkdir /templates
COPY --chmod=0444 samba.conf.tmpl /templates/smb.conf.tmpl
COPY --chmod=0444 smbclient-credentials.tmpl /templates/smbclient-credentials.tmpl
COPY --chmod=0444 ${DOCS} /templates/README.md
COPY --chmod=0755 scripts/backup-check.sh /scripts/backup-check.sh
COPY --chmod=0755 entrypoint /entrypoint

# Build-time Validation with goss
RUN ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s \
  CMD ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-healthcheck-tests.yaml validate || exit 1

EXPOSE 10445/tcp

ENTRYPOINT ["/entrypoint"]
