# Sophos Firewall Proxmox Deployment - Quick Reference

## Quick Start

```bash
# Download and run the script
wget https://raw.githubusercontent.com/YOUR-REPO/sophos-firewall-deploy.sh
chmod +x sophos-firewall-deploy.sh
./sophos-firewall-deploy.sh
```

## License Types Comparison

| Feature | Home Edition | Commercial |
|---------|-------------|------------|
| **Cost** | 🆓 FREE | 💰 Paid License |
| **CPU Cores** | Max 4 cores | Unlimited |
| **RAM** | Max 6GB | Unlimited |
| **Support** | Community only | Official Sophos Support |
| **License Key** | Not required | Required |
| **Installation** | ISO only | ISO or QCOW2 |
| **Use Case** | Home/Lab | Business/Enterprise |
| **Download** | [Free Download](https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition/software) | [Commercial Download](https://www.sophos.com/en-us/support/downloads/firewall-installers) |

## Installation Methods Comparison

| Feature | QCOW2 Method | ISO Method |
|---------|-------------|------------|
| **Speed** | ⚡ Fast (2-3 min) | 🐌 Slower (10-15 min) |
| **Download** | VI-*.KVM-*.zip | SW-*.iso |
| **Disk Config** | Pre-configured | Manual install |
| **Best For** | Quick deployment | Custom setup |
| **Boot Time** | 30-60 seconds | Full install process |

## File Downloads

### Home Edition (FREE)
```
💿 SW-21.5.0_GA-171.iso (~761 MB)
- No license key required
- Max 4 cores, 6GB RAM
- Community support
```

**Download:** https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition/software

### Commercial - QCOW2 Files (Virtual Installer - KVM)
```
📦 VI-21.5.0_GA.KVM-171.zip (~595 MB)
├── PRIMARY-DISK.qcow2 (32GB)
└── AUXILIARY-DISK.qcow2 (80GB)
- Requires license key
- No limitations
```

### Commercial - ISO File (Software Installer)
```
💿 SW-21.5.0_GA-171.iso (~761 MB)
- Requires license key
- No limitations
```

**Download:** https://www.sophos.com/en-us/support/downloads/firewall-installers

## Default VM Configuration

**General Settings:**
```yaml
VM ID: Auto-assigned (next available)
Name: sophos-firewall
Machine: q35
BIOS: OVMF (EFI)
Network 1: vmbr0 (WAN)
Network 2: vmbr1 (LAN)
Storage: local-lvm
QEMU Agent: DISABLED ⚠️ (Required!)
```

**Resource Allocation:**

| Setting | Commercial Default | Home Edition (Fixed) |
|---------|-------------------|---------------------|
| CPU Cores | 2 (customizable) | 4 (maximum) |
| RAM | 4096 MB (customizable) | 6144 MB (maximum) |

**Note:** Home Edition enforces maximum limits even if VM has more resources allocated.

## Common Commands

### VM Management
```bash
# Start VM
qm start <VMID>

# Stop VM
qm stop <VMID>

# Restart VM
qm reset <VMID>

# Check status
qm status <VMID>

# View configuration
qm config <VMID>

# Open console
qm terminal <VMID>
```

### Network Configuration
```bash
# List bridges
ip link show | grep vmbr
brctl show

# Add network interface
qm set <VMID> --net2 virtio,bridge=vmbr2
```

### Disk Management
```bash
# Resize PRIMARY disk (QCOW2 method only)
qm resize <VMID> scsi0 +10G

# Resize AUXILIARY disk
qm resize <VMID> scsi1 +20G

# Check disk usage
qm disk list <VMID>
```

### ISO Method Specific
```bash
# Attach ISO
qm set <VMID> --ide2 local:iso/SW-21.5.0_GA-171.iso,media=cdrom

# Remove ISO after installation
qm set <VMID> --ide2 none

# Change boot order back to disk
qm set <VMID> --boot order=scsi0
```

## Access Information

| Service | URL/Address | Default Credentials |
|---------|-------------|---------------------|
| Web Interface | https://172.16.16.16:4444 | admin / admin |
| Console | Proxmox UI | N/A |
| SSH (if enabled) | 172.16.16.16:22 | admin / admin |

⚠️ **Change default passwords immediately!**

## Post-Installation Checklist

### Home Edition (Free)
- [ ] VM started
- [ ] Opened console
- [ ] Completed installation wizard
- [ ] Selected "Home Edition" (no license key)
- [ ] Set admin password during install
- [ ] Removed ISO: `qm set <VMID> --ide2 none`
- [ ] VM rebooted
- [ ] Accessed https://172.16.16.16:4444
- [ ] Verified resource limits (4 cores, 6GB RAM)
- [ ] Configured network zones
- [ ] Joined Sophos Community for support
- [ ] Updated to latest firmware

### Commercial - QCOW2 Method
- [ ] VM started
- [ ] Waited 60 seconds for boot
- [ ] Accessed https://172.16.16.16:4444
- [ ] Entered license/serial number
- [ ] Completed setup wizard
- [ ] Changed default password
- [ ] Registered firewall
- [ ] Configured network zones
- [ ] Updated to latest firmware

### Commercial - ISO Method
- [ ] VM started
- [ ] Opened console
- [ ] Completed installation wizard
- [ ] Set admin password during install
- [ ] Removed ISO: `qm set <VMID> --ide2 none`
- [ ] VM rebooted
- [ ] Accessed https://172.16.16.16:4444
- [ ] Completed setup wizard
- [ ] Registered firewall
- [ ] Configured network zones
- [ ] Updated to latest firmware

## Troubleshooting Quick Fixes

### Can't access web interface
```bash
# Check if VM is running
qm status <VMID>

# Check network config
qm config <VMID> | grep net

# Restart VM
qm reset <VMID>
```

### VM won't start
```bash
# Check for errors
journalctl -u pveproxy -f

# Verify QEMU agent is disabled
qm config <VMID> | grep agent
# Should show: agent: 0

# Re-enable if wrong
qm set <VMID> --agent 0
```

### Forgot to disable QEMU agent
```bash
# Disable QEMU Guest Agent (CRITICAL!)
qm set <VMID> --agent 0

# Restart VM
qm reset <VMID>
```

### ISO won't boot
```bash
# Check ISO attachment
qm config <VMID> | grep ide2

# Set boot order
qm set <VMID> --boot order=ide2\;scsi0

# Restart
qm reset <VMID>
```

### Disk not found during ISO install
```bash
# Verify disks exist
qm config <VMID> | grep scsi

# Recreate if missing
qm set <VMID> --scsi0 local-lvm:32,format=qcow2
qm set <VMID> --scsi1 local-lvm:80,format=qcow2
```

## Performance Optimization

### For Production Use
```bash
# Increase CPU
qm set <VMID> --cores 4 --cpu host

# Increase RAM
qm set <VMID> --memory 8192

# Enable SSD emulation (if using SSD)
qm set <VMID> --scsi0 local-lvm:vm-<VMID>-disk-0,ssd=1

# Enable multiqueue networking
qm set <VMID> --net0 virtio,bridge=vmbr0,queues=4
qm set <VMID> --net1 virtio,bridge=vmbr1,queues=4
```

## Network Interface Mapping

| Proxmox | Sophos Firewall | Typical Use |
|---------|-----------------|-------------|
| net0 (vmbr0) | Port1 | WAN (Internet) |
| net1 (vmbr1) | Port2 | LAN (Internal) |
| net2 (vmbr2) | Port3 | DMZ (Optional) |
| net3 (vmbr3) | Port4 | Guest WiFi (Optional) |

## Backup Commands

```bash
# Create backup
vzdump <VMID> --mode snapshot --compress zstd

# Schedule backup (edit via UI)
# Datacenter → Backup → Add

# Restore from backup
qmrestore /var/lib/vz/dump/vzdump-qemu-<VMID>-*.vma.zst <NEW_VMID>
```

## Resource Requirements

### Home Edition (Limited by Sophos)
- **CPU**: Up to 4 cores (firewall will only use 4 even if more allocated)
- **RAM**: Up to 6GB (firewall will only use 6GB even if more allocated)
- **Disk**: 120 GB minimum
- **Network**: 2 interfaces minimum

### Commercial - Minimum (Small Office/Lab)
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk**: 120 GB
- **Network**: 2 interfaces

### Commercial - Recommended (Production)
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 200 GB
- **Network**: 3-4 interfaces

### Commercial - Enterprise
- **CPU**: 8+ cores
- **RAM**: 16+ GB
- **Disk**: 500+ GB
- **Network**: 4+ interfaces

## Important Notes

### ⚠️ Critical Settings
1. **QEMU Guest Agent MUST be disabled** (`--agent 0`)
2. **Minimum 4GB RAM** required
3. **Two network interfaces** required (WAN/LAN)
4. **EFI boot** required

### 📌 Default Settings
- Web UI: Port 4444 (HTTPS)
- Admin Interface: 172.16.16.16
- Default Credentials: admin/admin
- Console Access: Via Proxmox UI

### 🔒 Security Checklist
- [ ] Change default admin password
- [ ] Disable unused interfaces
- [ ] Configure firewall rules
- [ ] Enable automatic updates
- [ ] Set up backup schedule
- [ ] Review security policies
- [ ] Configure logging

## Quick Links

- **Download**: https://www.sophos.com/en-us/support/downloads/firewall-installers
- **Documentation**: https://docs.sophos.com/nsg/sophos-firewall/
- **Community**: https://community.sophos.com/
- **Support**: https://support.sophos.com/

## License Requirements

### Home Edition (Free)
- **Cost**: Completely FREE
- **Registration**: Optional (recommended for updates)
- **Support**: Community forums only
- **Download**: https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition/software
- **Limitations**: 4 cores, 6GB RAM
- **Use Case**: Home networks, labs, learning

### Commercial License
For production/business use, you'll need:
- Sophos Central account
- Valid license/subscription
- Serial number (provided with license)
- **Support**: Official Sophos technical support
- **No Limitations**: Use full hardware resources

### Community Support (Home Edition)
- Sophos Community Forums: https://community.sophos.com/sophos-xg-firewall/
- Community Wiki and Guides
- Peer-to-peer support
- No SLA or guaranteed response times

---

**Last Updated**: January 2026  
**Script Version**: 2.0.0  
**Tested On**: Proxmox VE 8.1+
