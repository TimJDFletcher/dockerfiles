ARG DEBIAN_VERSION="trixie-20251103-slim"
FROM debian:${DEBIAN_VERSION}

ARG SAMBA_VERSION="2:4.23.4+dfsg-1~bpo13+1"
ARG GOSS_VER="v0.4.9"
ARG GOSS_DST="/goss"
ARG BACKUPDIR="/backups"

ENV USER="timemachine" PASS="password" PUID="999" GID="999" LOG_LEVEL="1" QUOTA="1024"

ENV BACKUPDIR=${BACKUPDIR}
VOLUME ${BACKUPDIR}

RUN echo 'deb http://deb.debian.org/debian trixie-backports main' > /etc/apt/sources.list.d/backports.list 
RUN apt-get update && \
    apt-get --no-install-recommends --yes install -t stable-backports \
        samba="${SAMBA_VERSION}" \
        smbclient="${SAMBA_VERSION}" && \
    rm -rf /var/lib/apt/lists/* /etc/samba/smb.conf

COPY goss/ ${GOSS_DST}
RUN apt-get update && \
    apt-get --no-install-recommends --yes install curl ca-certificates && \
    sh ${GOSS_DST}/goss-installer && \
    apt-get purge --yes curl ca-certificates && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

COPY samba.conf.tmpl /etc/samba/smb.conf.tmpl
COPY TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

COPY --chmod=0755 entrypoint /entrypoint

RUN ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate 

HEALTHCHECK --interval=1m --timeout=10s \
  CMD {GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-healthcheck-tests.yaml validate || exit 1

EXPOSE 10445/tcp

ENTRYPOINT ["/entrypoint"]
