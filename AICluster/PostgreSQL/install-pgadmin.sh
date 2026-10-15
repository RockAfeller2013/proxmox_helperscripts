
#!/usr/bin/env bash
# https://www.pgadmin.org/download/pgadmin-4-apt/

# Remove the invalid repository entry
sudo rm -f /etc/apt/sources.list.d/pgadmin4.list

# Install prerequisites
sudo apt update
sudo apt install -y curl ca-certificates gnupg

# Add the official pgAdmin signing key
sudo mkdir -p /etc/apt/keyrings
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages-pgadmin-org.gpg

# Add the Debian 13 (Trixie) repository explicitly
echo "deb [signed-by=/etc/apt/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/trixie pgadmin4 main" \
  | sudo tee /etc/apt/sources.list.d/pgadmin4.list

# Update package lists
sudo apt update

sudo apt install -y pgadmin4-web
sudo /usr/pgadmin4/bin/setup-web.sh

echo
echo "pgAdmin installation and configuration completed."
echo "URL: http://<POSTGRESQL_LXC_IP>/pgadmin4"
