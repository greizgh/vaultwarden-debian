#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC="$DIR/git"
DST="$DIR/dist"

while getopts ":r:o:" opt; do
  case $opt in
    r) REF="$OPTARG"
    ;;
    o) OS_VERSION_NAME="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done
if [ -z "$REF" ]; then REF="1.13.0"; fi
if [ -z "$OS_VERSION_NAME" ]; then OS_VERSION_NAME=$(lsb_release -s -c); fi

# Clone bitwarden_rs
if [ ! -d "$SRC" ]; then
  git clone https://github.com/dani-garcia/bitwarden_rs.git "$SRC"
fi
cd "$SRC" || exit
CREF="$(git branch | grep \* | cut -d ' ' -f2)"
if [ "$CREF" != "$REF" ]; then
  git fetch
  git checkout "$REF" --force
else
  git clean -d -f
  git pull
fi
cd - || exit

# Prepare EnvFile
CONFIG="$DIR/debian/config.env"
cp "$SRC/.env.template" "$CONFIG"
sed -i "s#\# DATA_FOLDER=data#DATA_FOLDER=/var/lib/bitwarden_rs#" "$CONFIG"
sed -i "s#\# WEB_VAULT_FOLDER=web-vault/#WEB_VAULT_FOLDER=/usr/share/bitwarden_rs/web-vault/#" "$CONFIG"

mkdir -p "$DST"

# Prepare Dockerfile
patch -i "$DIR/Dockerfile.patch" "$SRC/docker/amd64/sqlite/Dockerfile" -o "$DIR/Dockerfile" || exit
sed -E "s/(FROM[[:space:]]*rust:)[^[:space:]]+(.+)/\1${OS_VERSION_NAME}\2/g" -i "$DIR/Dockerfile"
sed -E "s/(FROM[[:space:]]*debian:)[^-]+(-.+)/\1${OS_VERSION_NAME}\2/g" -i "$DIR/Dockerfile"

docker build -t bitwarden-deb "$DIR"

CID=$(docker run -d bitwarden-deb)
docker cp "$CID":/bitwarden_package/bitwarden-rs.deb "$DST/bitwarden_rs-$REF.deb"
docker rm "$CID"
