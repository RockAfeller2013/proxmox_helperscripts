# Sophos Firewall Deployment Script for Proxmox VE

A Proxmox VE helper script for automated deployment of Sophos Firewall VM, based on the official Sophos documentation and inspired by the community-scripts project style.

## Download

- Setup Account - https://community.sophos.com/sophos-xg-firewall/b/blog/posts/important-sophos-firewall-licensing-portal-changes
- Download - https://www.sophos.com/en-us/support/downloads

## Overview

This script automates the deployment of Sophos Firewall on Proxmox Virtual Environment with support for both **Home Edition (Free)** and **Commercial licenses**:

### License Types:

1. **Home Edition (Free)**
   - Free for personal/home use
   - Limited to 4 CPU cores
   - Limited to 6GB RAM
   - Community support only
   - No license key required
   - ISO installation only

2. **Commercial License**
   - Requires valid license/subscription
   - No CPU/RAM limitations
   - Full Sophos support
   - QCOW2 or ISO installation

### Installation Methods:

1. **ISO Method** - Traditional installation using Software Installer ISO (required for Home Edition)
2. **QCOW2 Method** - Uses pre-built KVM virtual disk images for quick deployment (Commercial only)

The script handles VM creation, disk configuration, and network setup according to Sophos best practices.

## Features

- ✅ Supports both Home Edition (free) and Commercial licenses
- ✅ Automatic enforcement of Home Edition limits (4 cores, 6GB RAM)
- ✅ Two installation methods: ISO (all licenses) or QCOW2 (commercial only)
- ✅ Interactive deployment with default and advanced settings
- ✅ Automatic VM creation with optimal settings
- ✅ Dual network interface configuration (WAN/LAN)
- ✅ QCOW2: Automatic disk extraction and import
- ✅ ISO: Automated disk creation and ISO attachment
- ✅ EFI boot configuration
- ✅ User-friendly colored output and progress indicators
- ✅ Error handling and validation
- ✅ Properly disables QEMU Guest Agent (required for Sophos)

## Prerequisites

- Proxmox VE 8.1 or higher
- AMD64 architecture (x86_64)
- Downloaded Sophos Firewall QCOW2 ZIP file
- Sufficient storage space (minimum 120GB recommended)
- At least 4GB RAM available for the VM
- Two network bridges configured (for WAN and LAN)

## Downloading Sophos Firewall

Before running the script, download the appropriate Sophos Firewall installer:

### Home Edition (Free - Recommended for Home Users)

**Download Page:** https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition/software

1. Visit the Home Edition download page
2. Click **"Download Now"**
3. Download the Software ISO (e.g., `SW-21.5.0_GA-171.iso`)
4. Transfer the ISO file to your Proxmox host

**What you get:**
- Free firewall for home use
- Full Sophos Firewall features
- Limited to 4 cores and 6GB RAM
- No license key required
- Community support

**Note:** Home Edition uses ISO installation only (no QCOW2 option)

### Commercial License

#### Option 1: QCOW2 (Recommended - Faster Deployment)

1. Visit [Sophos Firewall Installers](https://www.sophos.com/en-us/support/downloads/firewall-installers)
2. Scroll to **Virtual Installers: Firewall OS for KVM**
3. Click **Download** to get the ZIP file (e.g., `VI-21.5.0_GA.KVM-171.zip`)
4. Transfer the ZIP file to your Proxmox host

**What you get:**
- PRIMARY-DISK.qcow2 (~32GB)
- AUXILIARY-DISK.qcow2 (~80GB)
- Pre-configured, ready to boot
- Requires valid license/serial number

#### Option 2: ISO (Traditional Installation)

1. Visit [Sophos Firewall Installers](https://www.sophos.com/en-us/support/downloads/firewall-installers)
2. Scroll to **Software Installers: Firewall OS Software ISO for Intel Hardware**
3. Click **Download** to get the ISO file (e.g., `SW-21.5.0_GA-171.iso`)
4. Transfer the ISO file to your Proxmox host

**What you get:**
- Bootable installation ISO
- Interactive installation process
- Requires valid license/serial number

**Which license to choose?**
- **Home Edition**: Perfect for home networks, labs, learning - completely free!
- **Commercial**: For business use, advanced features, official support

## Installation

### Quick Start (Default Settings)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR-REPO/sophos-firewall-deploy.sh)
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/YOUR-REPO/sophos-firewall-deploy.sh
chmod +x sophos-firewall-deploy.sh
./sophos-firewall-deploy.sh
```

### Using Default Settings

The script will create a VM with these defaults:

| Setting | Default Value |
|---------|---------------|
| VM ID | Next available ID |
| VM Name | sophos-firewall |
| CPU Cores | 2 |
| RAM | 4096 MB |
| Primary Bridge | vmbr0 (WAN) |
| Secondary Bridge | vmbr1 (LAN) |
| Machine Type | q35 |
| Storage | local-lvm |

### Using Advanced Settings

Choose "Advanced" when prompted to customize:

- VM ID
- VM Name
- CPU Core count
- RAM allocation
- Network bridges (WAN/LAN)
- Machine type
- Storage location

## Usage

1. Run the script on your Proxmox host:
   ```bash
   ./sophos-firewall-deploy.sh
   ```

2. **Choose Installation Method**:
   - Select **QCOW2** for faster deployment with pre-built disks
   - Select **ISO** for traditional installation

3. Choose between **Default** or **Advanced** settings

4. Provide the file path when prompted:
   
   **For QCOW2 method:**
   ```
   /root/VI-21.5.0_GA.KVM-171.zip
   ```
   
   **For ISO method:**
   ```
   /root/SW-21.5.0_GA-171.iso
   ```

5. Wait for the script to complete

6. **For QCOW2 installations:**
   - Start the VM: `qm start <VMID>`
   - Wait 30-60 seconds for boot
   - Access web interface immediately
   
   **For ISO installations:**
   - Start the VM: `qm start <VMID>`
   - Open console in Proxmox UI
   - Follow installation wizard
   - After installation, remove ISO: `qm set <VMID> --ide2 none`
   - Access web interface

## Post-Installation

After the script completes:

### For QCOW2 Method:

1. **Start the VM**:
   ```bash
   qm start <VMID>
   ```

2. **Wait for Boot**: Allow 30-60 seconds for the firewall to fully boot

3. **Access Web Interface**:
   - Open your browser to: `https://172.16.16.16:4444`
   - Accept the self-signed certificate warning
   - Default IP is configured by Sophos

4. **Complete Setup Wizard**:
   - Review and accept Sophos End User Terms of Use
   - Click "Start setup" to begin registration
   - Follow the setup assistant for basic configuration

### For ISO Method:

1. **Start the VM**:
   ```bash
   qm start <VMID>
   ```

2. **Open Console**:
   - In Proxmox web UI, navigate to your VM
   - Click "Console" to open the VNC console

3. **Follow Installation Wizard**:
   - The installer will boot from the ISO
   - Select installation language
   - Choose disk configuration (PRIMARY and AUXILIARY disks are pre-created)
   - Set initial admin password
   - Wait for installation to complete

4. **Remove Installation Media**:
   ```bash
   qm set <VMID> --ide2 none
   ```

5. **Reboot if needed**:
   ```bash
   qm reset <VMID>
   ```

6. **Access Web Interface**:
   - Open your browser to: `https://172.16.16.16:4444`
   - Log in with credentials set during installation
   - Complete registration and basic setup

### Important Notes (Both Methods):

- The setup assistant won't start if you've changed the default password via CLI
- You can complete basic setup manually or reset to defaults to use the wizard
- Minimum 4GB RAM is required for production use
- Consider allocating more resources for production environments
- **CRITICAL**: QEMU Guest Agent is disabled - do NOT enable it as this will cause issues

## Network Configuration

The script creates two network interfaces:

- **net0** (Primary Bridge): WAN interface - typically connected to your internet-facing network
- **net1** (Secondary Bridge): LAN interface - typically connected to your internal network

Make sure your Proxmox bridges are properly configured before deployment:

```bash
# View current bridges
ip link show | grep vmbr

# Example bridge configuration in /etc/network/interfaces
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.10/24
    gateway 192.168.1.1
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0

auto vmbr1
iface vmbr1 inet static
    address 10.0.0.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

## Storage Considerations

The script supports both directory-based and LVM storage:

- **Directory/NFS Storage**: Disks are copied directly to the storage path
- **LVM/ZFS Storage**: Disks are imported using `qm importdisk`

Ensure your storage has adequate space:
- Primary disk: ~32GB
- Auxiliary disk: ~80GB
- Total recommended: 120GB+ free space

## Troubleshooting

### Script Won't Run

**Error**: Permission denied
```bash
chmod +x sophos-firewall-deploy.sh
```

**Error**: Not running as root
```bash
sudo ./sophos-firewall-deploy.sh
```

### ZIP File Not Found

Ensure you provide the absolute path:
```bash
# Wrong
VI-21.0.0_GA.KVM-123.zip

# Correct
/root/downloads/VI-21.0.0_GA.KVM-123.zip
```

### Storage Issues

**Error**: Invalid Storage

Check available storage:
```bash
pvesm status
```

Ensure the storage pool has enough free space:
```bash
pvesm status -storage local-lvm
```

### ISO Method Specific Issues

**ISO not booting**

Verify ISO is attached:
```bash
qm config <VMID> | grep ide2
```

Reattach if necessary:
```bash
qm set <VMID> --ide2 local:iso/SW-21.5.0_GA-171.iso,media=cdrom
```

**Installer can't find disks**

Check disk configuration:
```bash
qm config <VMID> | grep scsi
```

Disks should show as:
```
scsi0: local-lvm:vm-XXX-disk-0,size=32G
scsi1: local-lvm:vm-XXX-disk-1,size=80G
```

**Can't remove ISO after installation**

Force removal:
```bash
qm set <VMID> --delete ide2
```

Or use Proxmox web UI:
1. Select VM → Hardware
2. Select CD/DVD Drive (ide2)
3. Click "Edit" → Select "Do not use any media"
4. Click "OK"

### Network Bridge Not Found

List available bridges:
```bash
brctl show
# or
ip link show type bridge
```

Create a bridge if needed (see Network Configuration section above).

### VM Won't Boot

Check VM configuration:
```bash
qm config <VMID>
```

View VM console:
```bash
# Via Proxmox web UI
# Or via command line
qm terminal <VMID>
```

Check boot order:
```bash
qm set <VMID> --boot order=scsi0
```

### Can't Access Web Interface

1. Ensure VM is running:
   ```bash
   qm status <VMID>
   ```

2. Check network configuration:
   ```bash
   qm config <VMID> | grep net
   ```

3. Verify firewall rules aren't blocking port 4444

4. Try accessing from Proxmox host first:
   ```bash
   curl -k https://172.16.16.16:4444
   ```

## VM Management

### Start VM
```bash
qm start <VMID>
```

### Stop VM
```bash
qm stop <VMID>
```

### Restart VM
```bash
qm reset <VMID>
```

### View VM Status
```bash
qm status <VMID>
```

### View VM Configuration
```bash
qm config <VMID>
```

### Access Console
```bash
qm terminal <VMID>
```

### Delete VM
```bash
qm destroy <VMID>
```

## Performance Tuning

For production environments, consider:

### CPU Optimization
```bash
qm set <VMID> --cores 4
qm set <VMID> --cpu host
```

### Memory Adjustment
```bash
qm set <VMID> --memory 8192
```

### Disk Optimization
```bash
# Enable SSD emulation if using SSD storage
qm set <VMID> --scsi0 <storage>:vm-<VMID>-disk-0,ssd=1

# Enable discard for thin provisioning
qm set <VMID> --scsi0 <storage>:vm-<VMID>-disk-0,discard=on
```

### Network Performance
```bash
# Enable multiqueue for better network performance
qm set <VMID> --net0 virtio,bridge=vmbr0,queues=4
qm set <VMID> --net1 virtio,bridge=vmbr1,queues=4
```

## Security Recommendations

1. **Change Default Passwords**: Immediately after setup
2. **Enable Firewall Rules**: Configure appropriate access controls
3. **Update Regularly**: Keep Sophos Firewall updated
4. **Network Segmentation**: Use separate bridges for WAN/LAN
5. **Backup Configuration**: Regular backups of VM and firewall config
6. **Monitor Logs**: Review Sophos logs regularly
7. **Restrict Management Access**: Limit access to port 4444

## Backup and Recovery

### Create VM Backup
```bash
vzdump <VMID> --mode snapshot --storage <backup-storage>
```

### Schedule Automatic Backups
Configure in Proxmox Web UI:
1. Datacenter → Backup
2. Add backup job
3. Select VM and schedule

### Restore from Backup
```bash
qmrestore <backup-file> <VMID> --storage <storage>
```

## Additional Resources

- [Sophos Firewall Official Documentation](https://docs.sophos.com/nsg/sophos-firewall/)
- [Sophos Firewall KVM Installation Guide](https://docs.sophos.com/nsg/sophos-firewall/21.0/Help/en-us/webhelp/onlinehelp/VirtualAndSoftwareAppliancesHelp/KVM/ProxmoxInstall/index.html)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Community Scripts Project](https://community-scripts.github.io/ProxmoxVE/)

## License

This script is provided as-is for educational and deployment purposes. 

Sophos Firewall is a product of Sophos Limited and subject to their licensing terms.

## Credits

- Script inspired by [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
- Based on [Sophos Official Documentation](https://docs.sophos.com/)
- Created for the Proxmox VE community

## Contributing

Improvements and suggestions are welcome! Please ensure any modifications:
- Follow the existing code style
- Include appropriate error handling
- Update this README with relevant changes

## Disclaimer

This is an unofficial deployment script. Always verify the script content before running in production environments. Test in a lab environment first.

For official support, contact Sophos directly.

---

**Version**: 1.0.0  
**Last Updated**: January 2026  
**Tested On**: Proxmox VE 8.1+
