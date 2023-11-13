#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DST="$DIR/dist"
REF=""
RECOMMENDS=""

DB_TYPE="sqlite"
SYSTEMD_DB="true"
ARCH="amd64"
IMG="vaultwarden/server"

while getopts ":r:d:a:si:" opt; do
  case $opt in
    r) REF="$OPTARG"
    ;;
    d) DB_TYPE="$OPTARG"
    ;;
    a) ARCH="$OPTARG"
    ;;
    i) IMG="$OPTARG"
    ;;
    s) SYSTEMD_DB="false"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2 ; exit
    ;;
  esac
done
if [ -z "$REF" ]; then REF=$(curl -s https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c 1-); fi

# mysql and postgresql need additional libraries. Sqlite support is built into the vaultwarden binary
case $DB_TYPE in
  mysql)
    RECOMMENDS="mariadb-server"
    ;;

  postgresql)
    RECOMMENDS="postgresql"
    ;;
esac

DEBIANDIR="$DIR/debian"
mkdir -p "$DST"

CONFIG="$DEBIANDIR/config.env"
confTmpl="https://raw.githubusercontent.com/dani-garcia/vaultwarden/$REF/.env.template"
curl -s "$confTmpl" > "$CONFIG"
sed -i "s#\# DATA_FOLDER=data#DATA_FOLDER=/var/lib/vaultwarden#" "$CONFIG"
sed -i "s#\# WEB_VAULT_FOLDER=web-vault/#WEB_VAULT_FOLDER=/usr/share/vaultwarden/web-vault/#" "$CONFIG"
sed -i "s/Uncomment any of the following lines to change the defaults/Uncomment any of the following lines to change the defaults\n\n## Warning\n## The default systemd-unit does not allow any custom directories.\n## Be sure to check if the service has appropriate permissions before you set custom paths./g" "$CONFIG"

# Prepare Controlfile
CONTROL="$DEBIANDIR/control"
cp "$DIR/control.dist" "$CONTROL"
sed -i "s/Version:.*/Version: $REF-1/" "$CONTROL"
sed -i "s/Architecture:.*/Architecture: $ARCH/" "$CONTROL"
if [ -n "$RECOMMENDS" ]; then
  echo "Recommends: $RECOMMENDS" >> "$CONTROL"
fi

# Prepare Systemd-unit
SYSTEMD_UNIT="$DEBIANDIR/vaultwarden.service"
if [ "$SYSTEMD_DB" = true ] && [ "$DB_TYPE" = "mysql" ]; then
  sed -i "s/After=network.target/After=network.target mysqld.service\nRequires=mysqld.service/g" "$SYSTEMD_UNIT"
elif [ "$SYSTEMD_DB" = true ] && [ "$DB_TYPE" = "postgresql" ]; then
  sed -i "s/After=network.target/After=network.target postgresql.service\nRequires=postgresql.service/g" "$SYSTEMD_UNIT"
fi

out=$(mktemp -d)
docker build -t vaultwarden-deb --build-arg ref="$REF" --build-arg img="$IMG" .
docker run --rm -v "$out:/outdir" vaultwarden-deb
mv "$out/vaultwarden.deb" "$DST/vaultwarden-${REF}-${DB_TYPE}-${ARCH}.deb"
rmdir "$out"
