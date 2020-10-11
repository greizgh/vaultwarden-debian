#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC="$DIR/git"
DST="$DIR/dist"

while getopts ":r:o:d:" opt; do
  case $opt in
    r) REF="$OPTARG"
    ;;
    o) OS_VERSION_NAME="$OPTARG"
    ;;
    d) DB_TYPE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done
if [ -z "$REF" ]; then REF=$(curl -s https://api.github.com/repos/dani-garcia/bitwarden_rs/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c 1-); fi
if [ -z "$OS_VERSION_NAME" ]; then OS_VERSION_NAME='buster'; fi
if [ -z "$DB_TYPE" ]; then DB_TYPE="sqlite"; fi

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
sed -i "s/Uncomment any of the following lines to change the defaults/Uncomment any of the following lines to change the defaults\n\n## Warning\n## The default systemd-unit does not allow any custom directories.\n## Be sure to check if the service has appropriate permissions before you set custom paths./g" "$CONFIG"

mkdir -p "$DST"

# Prepare Dockerfile
patch -i "$DIR/Dockerfile.patch" "$SRC/docker/amd64/Dockerfile" --verbose -o "$DIR/Dockerfile" || exit
sed -E "s/(FROM[[:space:]]*rust:)[^[:space:]]+(.+)/\1${OS_VERSION_NAME}\2/g" -i "$DIR/Dockerfile"
sed -E "s/(FROM[[:space:]]*debian:)[^-]+(-.+)/\1${OS_VERSION_NAME}\2/g" -i "$DIR/Dockerfile"

# Prepare Controlfile
CONTROL="$DIR/debian/control"
cp "$DIR/control.dist" "$CONTROL"
sed -i "s/Version:.*/Version: $REF-1/" "$CONTROL"

# Prepare Systemd-unit
SYSTEMD_UNIT="$DIR/debian/bitwarden_rs.service"
if [ "$DB_TYPE" = "mysql" ]; then
  sed -i "s/After=network.target/After=network.target mysqld.service\nRequires=mysqld.service/g" "$SYSTEMD_UNIT"
elif [ "$DB_TYPE" = "postgresql" ]; then
  sed -i "s/After=network.target/After=network.target postgresql.service\nRequires=postgresql.service/g" "$SYSTEMD_UNIT"
fi

echo "[INFO] docker build -t bitwarden-deb "$DIR" --build-arg DB=$DB_TYPE"
docker build -t bitwarden-deb "$DIR" --build-arg DB=$DB_TYPE

CID=$(docker run -d bitwarden-deb)
docker cp "$CID":/bitwarden_package/bitwarden-rs.deb "$DST/bitwarden_rs-${OS_VERSION_NAME}-${REF}-${DB_TYPE}.deb"
docker rm "$CID"
