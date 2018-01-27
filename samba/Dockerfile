FROM debian:9

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends --yes install \
        acl \
        attr \
        autoconf \
        bind9utils \
        bison \
        build-essential \
        ca-certificates \
        debhelper \
        dnsutils \
        docbook-xml \
        docbook-xsl \
        flex \
        gdb \
        git \
        krb5-user \
        libacl1-dev \
        libaio-dev \
        libarchive-dev \
        libattr1-dev \
        libblkid-dev \
        libbsd-dev \
        libcap-dev \
        libcups2-dev \
        libgnutls28-dev \
        libgpgme11-dev \
        libjansson-dev \
        libjson-perl \
        libldap2-dev \
        libncurses5-dev \
        libpam0g-dev \
        libparse-yapp-perl \
        libpopt-dev \
        libreadline-dev \
        nettle-dev \
        perl \
        perl-modules \
        pkg-config \
        python-all-dev \
        python-crypto \
        python-dbg \
        python-dev \
        python-dnspython \
        python-gpgme \
        python-markdown \
        python3-dev \
        python3-dnspython \
        python3-gpgme \
        python3-markdown \
        xsltproc \
        zlib1g-dev


RUN mkdir -p /samba
RUN git clone https://git.samba.org/samba.git /samba/source

ENV GITTAG samba-4.8.0rc2

RUN cd /samba/source \
        && git checkout tags/$GITTAG \
        && ./configure --prefix=/samba --disable-cups --without-ad-dc \
        && make -j 2 \
        && make install

ADD samba.conf /samba/etc/smb.conf

RUN /samba/bin/testparm -s
ENV PASS password 

RUN useradd timemachine \
    && printf "$PASS\n$PASS\n" | /samba/bin/smbpasswd -s -a timemachine

EXPOSE 445/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]
