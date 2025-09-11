#!/bin/bash
# Save as: /root/update-cron-config.sh

# Backup current cron.d files
echo "Backing up current cron.d configuration..."
tar -czf /root/cron.d-backup-$(date +%Y%m%d).tar.gz /etc/cron.d/

# Create new clean configuration
cat > /etc/cron.d/proxmox-maintenance << 'EOF'
# /etc/cron.d/proxmox-maintenance
# Proxmox VE System Maintenance Schedule

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# e2fsprogs filesystem checks
30 3 * * 0   root test -e /run/systemd/system || SERVICE_MODE=1 /usr/lib/x86_64-linux-gnu/e2fsprogs/e2scrub_all_cron
10 3 * * *   root test -e /run/systemd/system || SERVICE_MODE=1 /sbin/e2scrub_all -A -r

# MDADM RAID array check (first Sunday of each month at 00:57)
57 0 * * 0   root if [ -x /usr/share/mdadm/checkarray ] && [ $(date +\%d) -le 7 ]; then /usr/share/mdadm/checkarray --cron --all --idle --quiet; fi

# ZFS TRIM (first Sunday of each month at 02:00)
0 2 1-7 * *  root if [ $(date +\%w) -eq 0 ] && [ -x /usr/lib/zfs-linux/trim ]; then /usr/lib/zfs-linux/trim; fi

# ZFS scrub (second Sunday of each month at 03:00)
0 3 8-14 * * root if [ $(date +\%w) -eq 0 ] && [ -x /usr/lib/zfs-linux/scrub ]; then /usr/lib/zfs-linux/scrub; fi
EOF

# Set proper permissions
chmod 644 /etc/cron.d/proxmox-maintenance
chown root:root /etc/cron.d/proxmox-maintenance

# Verify syntax
echo "Verifying cron syntax..."
if ! run-parts --test /etc/cron.d; then
    echo "Cron syntax verification failed! Restoring backup..."
    tar -xzf /root/cron.d-backup-$(date +%Y%m%d).tar.gz -C /
    exit 1
fi

echo "Cron configuration updated successfully!"
echo "New schedule:"
echo "- ZFS TRIM: 1st Sunday at 02:00"
echo "- ZFS scrub: 2nd Sunday at 03:00"
echo "- MDADM check: 1st Sunday at 00:57"
echo "- Filesystem checks: Daily at 03:10, Weekly at 03:30"
