ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="dyndnsd.rb" \
    org.opencontainers.image.description="Small, lightweight and extensible DynDNS server written with Ruby and Rack" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/dyndnsd" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/dyndnsd" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

RUN set -xe; \
    \
    umask 0022; \
    \
    pkg update; \
    pkg install -U FreeBSD-set-base-jail nsd doas devel/ruby-gems rubygem-atomic; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*

RUN umask 0022; \
    \
    gem install dyndnsd
