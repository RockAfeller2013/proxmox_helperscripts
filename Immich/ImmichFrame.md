- bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/immichframe.sh)"

After installation, edit /opt/immichframe/Config/Settings.yml and set ImmichServerUrl and ApiKey. Then restart the service with systemctl restart immichframe.
