ARG DEBIAN_VERSION="trixie-20260112-slim"
FROM debian:${DEBIAN_VERSION}

# Arguments
ARG SAMBA_VERSION="2:4.23.5+dfsg-1~bpo13+1"
ARG GOSS_VER="v0.4.9"
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
    BACKUPDIR=${BACKUPDIR}

# Setup Volume
VOLUME ${BACKUPDIR}

# Install Dependencies & Samba
COPY goss/ ${GOSS_DST}
RUN echo 'deb http://deb.debian.org/debian trixie-backports main' > /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    # Install runtime dependencies and Samba
    apt-get --no-install-recommends --yes install \
        curl \
        ca-certificates \
        gettext-base \
    && \
    apt-get --no-install-recommends --yes install -t trixie-backports \
        samba="${SAMBA_VERSION}" \
        smbclient="${SAMBA_VERSION}" \
    && \
    # Install Goss (requires curl/ca-certificates)
    sh ${GOSS_DST}/goss-installer && \
    # Cleanup
    apt-get purge --yes curl ca-certificates && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/* /etc/samba/smb.conf

# Configuration & Scripts
RUN mkdir /templates
COPY --chmod=0444 samba.conf.tmpl /templates/smb.conf.tmpl
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
