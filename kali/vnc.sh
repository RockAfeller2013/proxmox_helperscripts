mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/cloudinit-kali.yaml <<'EOF'
#cloud-config
package_update: true
package_upgrade: true
package_reboot_if_required: true

users:
  - default
  - name: kali
    sudo: ALL=(ALL) NOPASSWD:ALL

bootcmd:
  - echo "192.168.1.130 us.archive.ubuntu.com" >> /etc/hosts
  - cloud-init-per once mymkfs mkfs.ext4 /dev/vdb

packages:
  - pwgen
  - ufw
  - novnc
  - x11vnc

write_files:
  - path: /etc/systemd/system/x11vnc.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Start x11vnc at startup
      After=display-manager.service

      [Service]
      ExecStart=/usr/bin/x11vnc -display :0 -autoport -localhost -nopw -xkb -ncache -ncache_cr -quiet -forever
      Restart=always
      User=kali

      [Install]
      WantedBy=multi-user.target

  - path: /etc/systemd/system/novnc.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Start noVNC proxy at startup
      After=network.target x11vnc.service

      [Service]
      ExecStart=/usr/share/novnc/utils/novnc_proxy --listen 8081 --vnc localhost:5900
      Restart=always
      User=kali

      [Install]
      WantedBy=multi-user.target

runcmd:
  # Disable IPv6 runtime
  - sysctl -w net.ipv6.conf.all.disable_ipv6=1
  - sysctl -w net.ipv6.conf.default.disable_ipv6=1
  - sysctl -w net.ipv6.conf.lo.disable_ipv6=1

  # Make IPv6 disable permanent
  - sed -i '/^GRUB_CMDLINE_LINUX=/ s/"$/ ipv6.disable=1"/' /etc/default/grub
  - update-grub

  # Disable firewall
  - systemctl stop ufw
  - systemctl disable ufw

  # Enable and start services
  - systemctl daemon-reload
  - systemctl enable --now x11vnc.service
  - systemctl enable --now novnc.service

  # Example fetch
  - mkdir -p /run/mydir
  - wget http://slashdot.org -O /run/mydir/index.html
EOF
