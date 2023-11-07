# vaultwarden debian package helper

[vaultwarden](https://github.com/dani-garcia/vaultwarden) is an "Unofficial Bitwarden compatible server written in Rust".

This repository will help you produce a debian package.

## TL;DR

Make sure you have the required build dependencies:
* docker
* curl

Then:

```
git clone https://github.com/greizgh/vaultwarden-debian.git
cd vaultwarden-debian
./build.sh -r <version> # target vaultwarden version >= 1.30.0
```

### Options

- `-r`: specify vaultwarden version, it will default to the latest release
- `-a`: override architecture (default to `amd64`), read below
- `-d`: DB type, can be `sqlite`(default), `mysql` or `postgresql`
- `-s`: do not wait for DB in systemd service (only relevant for `mysql` or `postgresql`)

The `build.sh` script will reuse upstream binary from release images.

Building for will target the same architecture than the docker daemon's one.
In order to build for arm64, you need an arm64 docker host.
Then pass the `-a arm64` flag to properly set the control file (this will only impact the control file, this is NOT cross compilation).


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
