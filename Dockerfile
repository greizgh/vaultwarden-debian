ARG ref
ARG img="vaultwarden/server"
FROM $img:$ref
RUN mkdir /outdir
RUN mkdir -p /vaultwarden_package/DEBIAN
RUN mkdir -p /vaultwarden_package/usr/local/bin
RUN mkdir -p /vaultwarden_package/usr/lib/systemd/system
RUN mkdir -p /vaultwarden_package/etc/vaultwarden
RUN mkdir -p /vaultwarden_package/usr/share/vaultwarden

WORKDIR /vaultwarden_package
COPY debian/control /vaultwarden_package/DEBIAN/control
COPY debian/postinst /vaultwarden_package/DEBIAN/postinst
COPY debian/conffiles /vaultwarden_package/DEBIAN/conffiles
COPY debian/config.env /vaultwarden_package/etc/vaultwarden
COPY debian/vaultwarden.service /vaultwarden_package/usr/lib/systemd/system

RUN cp -r /web-vault /vaultwarden_package/usr/share/vaultwarden \
    && cp /vaultwarden /vaultwarden_package/usr/local/bin/

CMD dpkg-deb --build . /outdir/vaultwarden.deb
