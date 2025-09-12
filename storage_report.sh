#!/bin/bash
# Proxmox Disk Space Report Generator
REPORT_FILE="/root/proxmox_disk_report_$(date +%Y%m%d_%H%M%S).txt"

echo "=== PROXMOX COMPREHENSIVE DISK SPACE REPORT ===" > $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "Hostname: $(hostname)" >> $REPORT_FILE
echo "==============================================" >> $REPORT_FILE

# 1. System Filesystem Usage
echo "" >> $REPORT_FILE
echo "1. FILESYSTEM USAGE:" >> $REPORT_FILE
echo "====================" >> $REPORT_FILE
df -hT -x tmpfs -x devtmpfs >> $REPORT_FILE

# 2. Block Devices Overview
echo "" >> $REPORT_FILE
echo "2. BLOCK DEVICES DETAILS:" >> $REPORT_FILE
echo "=========================" >> $REPORT_FILE
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,UUID >> $REPORT_FILE

# 3. Proxmox Storage Configuration
echo "" >> $REPORT_FILE
echo "3. PROXMOX STORAGE CONFIGURATION:" >> $REPORT_FILE
echo "================================" >> $REPORT_FILE
pvesm status >> $REPORT_FILE

# 4. Proxmox Storage Content Summary
echo "" >> $REPORT_FILE
echo "4. PROXMOX STORAGE CONTENT SUMMARY:" >> $REPORT_FILE
echo "===================================" >> $REPORT_FILE
for storage in $(pvesm status | awk '{print $1}'); do
    if [ "$storage" != "Name" ]; then
        echo "--- $storage ---" >> $REPORT_FILE
        pvesm list $storage 2>/dev/null | head -10 >> $REPORT_FILE
        echo "" >> $REPORT_FILE
    fi
done

# 5. LVM Information (if available)
echo "" >> $REPORT_FILE
echo "5. LVM STATUS:" >> $REPORT_FILE
echo "==============" >> $REPORT_FILE
if command -v pvs >/dev/null 2>&1; then
    echo "Physical Volumes:" >> $REPORT_FILE
    pvs >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Volume Groups:" >> $REPORT_FILE
    vgs >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Logical Volumes:" >> $REPORT_FILE
    lvs >> $REPORT_FILE
else
    echo "LVM not detected on this system" >> $REPORT_FILE
fi

# 6. LVM-Thin Specific Information
echo "" >> $REPORT_FILE
echo "6. LVM-THIN STATUS:" >> $REPORT_FILE
echo "===================" >> $REPORT_FILE
echo "Key Point: For LVM-Thin, always monitor BOTH data_percent and metadata_percent." >> $REPORT_FILE
echo "If metadata reaches 100%, the pool becomes unusable even if free space exists." >> $REPORT_FILE
if command -v lvs >/dev/null 2>&1; then
    echo "" >> $REPORT_FILE
    echo "Thin Pools:" >> $REPORT_FILE
    lvs -o lv_name,vg_name,lv_size,data_percent,metadata_percent,lv_attr | grep thin >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Thin Volumes (sample):" >> $REPORT_FILE
    lvs -o name,size,data_percent,metadata_percent,pool_lv,origin,attr | grep -E "([^ ]*_thin|^LV)" | head -20 >> $REPORT_FILE
else
    echo "LVM tools not available" >> $REPORT_FILE
fi

# 7. ZFS Status (if available)
echo "" >> $REPORT_FILE
echo "7. ZFS STATUS:" >> $REPORT_FILE
echo "==============" >> $REPORT_FILE
if command -v zpool >/dev/null 2>&1; then
    echo "ZFS Pools:" >> $REPORT_FILE
    zpool list >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "ZFS Datasets:" >> $REPORT_FILE
    zfs list | head -15 >> $REPORT_FILE
else
    echo "ZFS not detected on this system" >> $REPORT_FILE
fi

# 8. Directory Usage Analysis
echo "" >> $REPORT_FILE
echo "8. KEY DIRECTORY USAGE:" >> $REPORT_FILE
echo "======================" >> $REPORT_FILE
echo "Proxmox directories:" >> $REPORT_FILE
du -sh /var/lib/vz 2>/dev/null >> $REPORT_FILE
du -sh /var/lib/vz/* 2>/dev/null >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "Other system directories:" >> $REPORT_FILE
du -sh /root /home /tmp /var/log 2>/dev/null >> $REPORT_FILE

# 9. Critical Usage Warnings
echo "" >> $REPORT_FILE
echo "9. CRITICAL USAGE WARNINGS:" >> $REPORT_FILE
echo "===========================" >> $REPORT_FILE

# Check filesystems over 80%
echo "Filesystems over 80% capacity:" >> $REPORT_FILE
df -h | awk 'NR>1 {gsub(/%/,""); if ($5 > 80) print $0}' >> $REPORT_FILE

# Check thin pools with high usage
if command -v lvs >/dev/null 2>&1; then
    echo "" >> $REPORT_FILE
    echo "Thin pools with high usage (over 80% in data or metadata):" >> $REPORT_FILE
    lvs -o name,data_percent,metadata_percent,attr 2>/dev/null | grep thin | \
    awk '{if ($2+0 > 80 || $3+0 > 80) print $0 "  <-- WARNING"}' >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "Reminder: If metadata reaches 100%, the pool becomes unusable immediately." >> $REPORT_FILE
fi

# 10. System Information
echo "" >> $REPORT_FILE
echo "10. SYSTEM INFORMATION:" >> $REPORT_FILE
echo "======================" >> $REPORT_FILE
echo "Uptime: $(uptime)" >> $REPORT_FILE
echo "Proxmox Version: $(pveversion 2>/dev/null || echo "Not available")" >> $REPORT_FILE
echo "Memory: $(free -h | awk '/Mem:/ {print $3"/"$2}')" >> $REPORT_FILE

echo "" >> $REPORT_FILE
echo "=== REPORT COMPLETE ===" >> $REPORT_FILE
echo "Report saved to: $REPORT_FILE" >> $REPORT_FILE

# Display report location
echo "Report generated: $REPORT_FILE"
echo ""
echo "To view the report:"
echo "  cat $REPORT_FILE"
echo ""
echo "To monitor live disk usage:"
echo "  watch -n 5 'df -h; echo; pvesm status'"
