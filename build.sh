#!/usr/bin/env bash

set -e

if [ -d "$1/git" ]; then
  cd "$1/git" || exit
  git pull
  cd - || exit
else
  git clone https://github.com/dani-garcia/bitwarden_rs.git "$1/git"
fi
docker build -t bitwarden-deb "$1"
CID=$(docker run -d bitwarden-deb)
mkdir -p "$1/build"
docker cp "$CID":/bitwarden_package/bitwarden-rs.deb "$1/build"
docker rm "$CID"
