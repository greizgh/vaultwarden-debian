#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC="$DIR/git"
DST="$DIR/dist"
if [ -z "$1" ]; then REF="master"; else REF="$1"; fi

# Clone bitwarden_rs
if [ ! -d "$SRC" ]; then
  git clone https://github.com/dani-garcia/bitwarden_rs.git "$SRC"
fi
cd "$SRC" || exit
git fetch
git checkout "origin/$REF"
cd - || exit

# Prepare EnvFile
CONFIG="$DIR/debian/config.env"
cp "$SRC/.env.template" "$CONFIG"
sed -i "s#\# DATA_FOLDER=data#DATA_FOLDER=/var/lib/bitwarden_rs#" "$CONFIG"
sed -i "s#\# WEB_VAULT_FOLDER=web-vault/#WEB_VAULT_FOLDER=/usr/share/bitwarden_rs/web-vault/#" "$CONFIG"

mkdir -p "$DST"

# Prepare Dockerfile
patch -i "$DIR/Dockerfile.patch" "$SRC/docker/amd64/sqlite/Dockerfile" -o "$DIR/Dockerfile"

docker build -t bitwarden-deb "$DIR"

CID=$(docker run -d bitwarden-deb)
docker cp "$CID":/bitwarden_package/bitwarden-rs.deb "$DST/bitwarden_rs-$REF.deb"
docker rm "$CID"
