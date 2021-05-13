#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC="$DIR/git"
DST="$DIR/dist"

OS_VERSION_NAME="buster"
DB_TYPE="sqlite"
ARCH_DIR="amd64"
PACKAGENAME="vaultwarden"
PACKAGEDIR="vaultwarden"
SERVICEUSER="vaultwarden"
EXECUTABLENAME="$PACKAGEDIR"

while getopts ":r:o:d:a:p:i:u:e:" opt; do
  case $opt in
    r) REF="$OPTARG"
    ;;
    o) OS_VERSION_NAME="$OPTARG"
    ;;
    d) DB_TYPE="$OPTARG"
    ;;
    a) ARCH_DIR="$OPTARG"
    ;;
    p) PACKAGENAME="$OPTARG"
    ;;
    i) PACKAGEDIR="$OPTARG"
    ;;
    u) SERVICEUSER="$OPTARG"
    ;;
    e) EXECUTABLENAME="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2 ; exit
    ;;
  esac
done
if [ -z "$REF" ]; then REF=$(curl -s https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c 1-); fi
ARCH=$ARCH_DIR
if [[ "$ARCH" =~ ^arm ]]; then ARCH="armhf"; fi

# Clone vaultwarden
if [ ! -d "$SRC" ]; then
  git clone https://github.com/dani-garcia/vaultwarden.git "$SRC"
fi
pushd "$SRC" || exit
CREF="$(git branch | grep "\*" | cut -d ' ' -f2)"
if [ "$CREF" != "$REF" ]; then
  git fetch || exit
  git checkout "$REF" --force || exit
else
  git pull || exit
fi
git clean -d -f || exit
popd || exit

DEBIANDIR="$SRC/debian"
mkdir -p "$DEBIANDIR"

SEDCOMMANDS="
s/@@PACKAGENAME@@/$PACKAGENAME/g
s/@@PACKAGEDIR@@/$PACKAGEDIR/g
s/@@SERVICEUSER@@/$SERVICEUSER/g
s/@@EXECUTABLENAME@@/$EXECUTABLENAME/g
"

# Prepare EnvFile
CONFIG="$DEBIANDIR/config.env"
cp "$SRC/.env.template" "$CONFIG"
sed -i "s#\# DATA_FOLDER=data#DATA_FOLDER=/var/lib/$PACKAGEDIR#" "$CONFIG"
sed -i "s#\# WEB_VAULT_FOLDER=web-vault/#WEB_VAULT_FOLDER=/usr/share/$PACKAGEDIR/web-vault/#" "$CONFIG"
sed -i "s/Uncomment any of the following lines to change the defaults/Uncomment any of the following lines to change the defaults\n\n## Warning\n## The default systemd-unit does not allow any custom directories.\n## Be sure to check if the service has appropriate permissions before you set custom paths./g" "$CONFIG"

# Prepare conffiles
sed conffiles.dist > "$DEBIANDIR/conffiles" -f <( echo "$SEDCOMMANDS" ) || exit
chmod 644 "$DEBIANDIR/conffiles"

# Prepare postinst
sed postinst.dist > "$DEBIANDIR/postinst" -f <( echo "$SEDCOMMANDS" ) || exit
chmod 755 "$DEBIANDIR/postinst"

mkdir -p "$DST"

# Prepare Dockerfile
sed "$DIR/patch/$ARCH_DIR/Dockerfile.patch" -f <( echo "$SEDCOMMANDS" ) | \
patch "$SRC/docker/$ARCH_DIR/Dockerfile" --verbose -o "$DIR/Dockerfile" || \
exit

sed -E "s/(FROM[[:space:]]*rust:)[^[:space:]]+(.+)/\1${OS_VERSION_NAME}\2/g" -i "$DIR/Dockerfile"
sed -E "s/(FROM[[:space:]]*debian:)[^-]+(-.+)/\1${OS_VERSION_NAME}\2/g" -i "$DIR/Dockerfile"

# Prepare Controlfile
CONTROL="$DEBIANDIR/control"
cp "$DIR/control.dist" "$CONTROL"
sed -i "s/@@PACKAGENAME@@/$PACKAGENAME/g" "$CONTROL"
sed -i "s/Version:.*/Version: $REF-1/" "$CONTROL"
sed -i "s/Architecture:.*/Architecture: $ARCH/" "$CONTROL"

# Prepare Systemd-unit
SYSTEMD_UNIT="$DEBIANDIR/$EXECUTABLENAME.service"
sed "$DIR/service.dist" > "$SYSTEMD_UNIT" -f <( echo "$SEDCOMMANDS" ) || exit
if [ "$DB_TYPE" = "mysql" ]; then
  sed -i "s/After=network.target/After=network.target mysqld.service\nRequires=mysqld.service/g" "$SYSTEMD_UNIT"
elif [ "$DB_TYPE" = "postgresql" ]; then
  sed -i "s/After=network.target/After=network.target postgresql.service\nRequires=postgresql.service/g" "$SYSTEMD_UNIT"
fi

echo "[INFO] docker build -t vaultwarden-deb $DIR --build-arg DB=$DB_TYPE"
docker build -t vaultwarden-deb "$SRC" --build-arg DB="$DB_TYPE" --target dpkg -f "$DIR/Dockerfile"

CID=$(docker run -d vaultwarden-deb)
docker cp "$CID:/vaultwarden_package/${PACKAGEDIR}.deb" "$DST/${PACKAGEDIR}-${OS_VERSION_NAME}-${REF}-${DB_TYPE}-${ARCH_DIR}.deb"
docker rm "$CID"
