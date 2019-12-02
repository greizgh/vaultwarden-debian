# Bitwarden_rs debian package helper

[Bitwarden_rs](https://github.com/dani-garcia/bitwarden_rs) is an "Unofficial Bitwarden compatible server written in Rust".

This repository will help you produce a debian package.

## TL;DR

Make sure you have the required build dependencies:
* docker
* git
* patch

Then:

```
git clone https://github.com/greizgh/bitwarden_rs-debian.git
cd bitwarden_rs-debian
./build.sh -r 1.10.0
```

The `build.sh` script will build bitwarden_rs for the same Debian version which targets bitwarden_rs.
To compile for a different Debian version, specify the release name (e.g. Stretch, Buster) using the `-o` option.

```
./build.sh -o stretch
```

## Post installation

The packaged systemd unit is **disabled**, you need to configure bitwarden_rs through its
[EnvFile](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Command%20lines):
`/etc/bitwarden_rs/config.env`

You will also probably want to setup a reverse proxy.
