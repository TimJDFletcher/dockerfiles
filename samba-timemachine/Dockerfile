FROM debian:trixie-20241016-slim

ENV USER="timemachine" PASS="password" PUID="999" GID="999" LOG_LEVEL="1" QUOTA="1024"
ENV BACKUPDIR="/backups"
VOLUME /backups

ENV SAMBA_VERSION="2:4.21.1+dfsg-2"
RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        samba="${SAMBA_VERSION}" \
        smbclient="${SAMBA_VERSION}" && \
    rm -rf /var/lib/apt/lists/* /etc/samba/smb.conf

ENV GOSS_VER="v0.4.9" GOSS_DST="/goss"
COPY goss/ /goss/
RUN apt-get update && \
    apt-get --no-install-recommends --yes install curl ca-certificates && \
    sh /goss/goss-installer && \
    apt-get purge --yes curl ca-certificates && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

COPY samba.conf.tmpl /etc/samba/smb.conf.tmpl
COPY TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

COPY entrypoint /entrypoint
RUN chmod 0755 /entrypoint

RUN ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate 

EXPOSE 10445/tcp

ENTRYPOINT ["/entrypoint"]
