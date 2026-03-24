# Pre-built goss image with patched Go dependencies
# Build first: cd ../goss && ./run build
ARG GOSS_IMAGE="timjdfletcher/goss:latest"
ARG DEBIAN_VERSION="trixie-20260316-slim"

FROM ${GOSS_IMAGE} AS goss

FROM debian:${DEBIAN_VERSION}

# Arguments
ARG SAMBA_VERSION="2:4.23.6+dfsg-2~bpo13+1"
ARG GOSS_VER="v0.4.9-patched"
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

# Copy goss binary from pre-built image (no curl needed!)
COPY --from=goss /goss ${GOSS_DST}/goss

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
