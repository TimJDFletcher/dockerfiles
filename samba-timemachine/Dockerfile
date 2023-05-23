FROM debian:bookworm-20230502-slim

ENV SAMBA_VERSION="2:4.17.8+dfsg-1"
ENV GOSS_VERSION="v0.3.22"
ENV GOSS_DST="/goss"

ENV BACKUPDIR=/backups
VOLUME /backups

RUN apt update && \
    apt --no-install-recommends --yes install \
        samba="$SAMBA_VERSION" \
        samba-vfs-modules="$SAMBA_VERSION"  && \
    rm -rf /var/lib/apt/lists/* /etc/samba/smb.conf

ADD samba.conf.tmpl /etc/samba/smb.conf.tmpl
ADD TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

EXPOSE 445/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ADD goss/ /goss/

RUN apt update && \
    apt --no-install-recommends --yes install curl ca-certificates && \
    sh /goss/goss-installer && \
    /goss/goss --gossfile /goss/tests/goss-build-test.yaml validate && \
    apt purge --yes curl ca-certificates && \
    apt autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/entrypoint"]
