FROM debian:bookworm-20230522-slim

ENV USER="timemachine" PASS="password" PUID="999" GID="999" LOG_LEVEL="1" QUOTA="1024"
ENV BACKUPDIR="/backups"
VOLUME /backups

ENV SAMBA_VERSION="2:4.17.8+dfsg-1"
RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        samba="${SAMBA_VERSION}" \
        samba-vfs-modules="${SAMBA_VERSION}" \
        smbclient=${SAMBA_VERSION} && \
    rm -rf /var/lib/apt/lists/* /etc/samba/smb.conf
COPY samba.conf.tmpl /etc/samba/smb.conf.tmpl
COPY TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

ENV GOSS_VER="v0.3.22" GOSS_DST="/goss"
COPY goss/ /goss/
RUN apt-get update && \
    apt-get --no-install-recommends --yes install curl ca-certificates && \
    sh /goss/goss-installer && \
    apt-get purge --yes curl ca-certificates && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 10445/tcp

COPY entrypoint /entrypoint
RUN chmod 0755 /entrypoint

RUN /${GOSS_DST}/goss --gossfile /${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate 

ENTRYPOINT ["/entrypoint"]
