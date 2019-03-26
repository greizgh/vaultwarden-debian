#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC="$DIR/git"
DST="$DIR/dist"

if [ -d "$SRC" ]; then
  cd "$SRC" || exit
  git pull
  cd - || exit
else
  git clone https://github.com/dani-garcia/bitwarden_rs.git "$SRC"
fi
mkdir -p "$DST"

docker build -t bitwarden-deb "$DIR"

CID=$(docker run -d bitwarden-deb)
docker cp "$CID":/bitwarden_package/bitwarden-rs.deb "$DST"
docker rm "$CID"
