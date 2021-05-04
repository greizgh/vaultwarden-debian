# vaultwarden debian package helper

[vaultwarden](https://github.com/dani-garcia/vaultwarden) is an "Unofficial Bitwarden compatible server written in Rust".

This repository will help you produce a debian package.

## TL;DR

Make sure you have the required build dependencies:
* docker
* git
* patch
* curl

Then:

```
git clone https://github.com/greizgh/vaultwarden-debian.git
cd vaultwarden-debian
./build.sh -r <version> # target vaultwarden version, example 1.19.0
```

The `build.sh` script will build vaultwarden for the same Debian version which targets vaultwarden.
That means, to build vaultwarden v1.19.0, make sure to checkout tag `v1.19.0` of this project.

To compile for a different Debian version, specify the release name (e.g. Stretch, Buster) using the `-o` option. You can compile for arm32v7 or amd64 architecture using the `-a` option, only the Buster (default) release of debian is supported by arm32v7.

```
./build.sh -o stretch
```

## Post installation

The packaged systemd unit is **disabled**, you need to configure vaultwarden through its
[EnvFile](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Command%20lines):
`/etc/vaultwarden/config.env`

You will also probably want to setup a reverse proxy.


## License

    vaultwarden-debian is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    vaultwarden-debian is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

See [COPYING](./COPYING) for the full license.

Please note this does not assume anything about [vaultwarden](https://github.com/dani-garcia/vaultwarden)'s own license.
