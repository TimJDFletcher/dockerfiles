FROM alpine:3.16.2

ENV BACKUPDIR=/backups
VOLUME /backups

RUN apk add --no-cache samba-common-tools samba-server bash procps iproute2

ADD samba.conf.tmpl /etc/samba/smb.conf.tmpl
ADD TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

EXPOSE 445/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]