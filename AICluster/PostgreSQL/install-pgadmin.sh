
#!/usr/bin/env bash
# https://www.pgadmin.org/download/pgadmin-4-apt/
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    echo "Cannot identify the Linux distribution."
    exit 1
fi

. /etc/os-release

if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
    echo "Unsupported distribution: $ID"
    exit 1
fi

if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
    echo "This script requires amd64."
    exit 1
fi

if [[ -z "${VERSION_CODENAME:-}" ]]; then
    echo "Cannot determine the distribution codename."
    exit 1
fi

echo "Installing pgAdmin 4 Web on $PRETTY_NAME..."

apt-get update
apt-get install -y curl ca-certificates gnupg

install -d -m 0755 /etc/apt/keyrings

curl -fsSL \
    https://www.pgadmin.org/static/packages_pgadmin_org.pub \
    | gpg --dearmor --yes \
        -o /etc/apt/keyrings/packages-pgadmin-org.gpg

chmod 0644 /etc/apt/keyrings/packages-pgadmin-org.gpg

echo "deb [signed-by=/etc/apt/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/${VERSION_CODENAME} pgadmin4 main" \
    > /etc/apt/sources.list.d/pgadmin4.list

apt-get update
apt-get install -y pgadmin4-web

echo "Starting pgAdmin web configuration..."
/usr/pgadmin4/bin/setup-web.sh

echo
echo "pgAdmin installation and configuration completed."
echo "URL: http://<POSTGRESQL_LXC_IP>/pgadmin4"
