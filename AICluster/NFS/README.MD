```bash
/volume2/PROXMOX_NFS
synology-backups
192.168.1.146
NFS Version: 4.1
```

# Extend PostgreSQL VM Storage Using Synology NAS

## Architecture

Use Synology NFS storage for additional capacity. Keep the PostgreSQL database on a virtual disk hosted by Proxmox for better isolation and predictable performance, where possible.

## 1. Configure Synology NAS

1. Open **Control Panel → File Services → NFS**.
2. Enable NFS.
3. Open **Control Panel → Shared Folder → Create**.
4. Create a shared folder named `postgres-storage`.
5. Edit the folder and open **NFS Permissions → Create**.
6. Configure:
   - Hostname/IP: Proxmox or PostgreSQL VM IP, depending on the NFS client.
   - Privilege: Read/Write.
   - Squash: Map all users to admin, only if required and understood.
   - Security: `sys`.
7. Save the NFS export path, for example `/volume1/postgres-storage`.

Restrict access to trusted IP addresses. See the [Synology NFS guide](https://kb.synology.com/en-sg/DSM/tutorial/how_to_set_up_Synology_NFS_share_as_Proxmox_storage).

## 2. Mount NFS in the PostgreSQL VM

Run inside the Debian/Ubuntu PostgreSQL VM:

```bash
sudo apt update
sudo apt install -y nfs-common
sudo mkdir -p /mnt/postgres-nas

sudo mount -t nfs \
  192.168.1.146:/volume1/postgres-storage \
  /mnt/postgres-nas

df -h /mnt/postgres-nas
```

Replace the NAS IP and export path with your actual values.

## 3. Configure Persistent Mounting

Add the following entry to `/etc/fstab`:

```fstab
192.168.1.146:/volume1/postgres-storage /mnt/postgres-nas nfs defaults,_netdev,nofail 0 0
```

Test the configuration:

```bash
sudo umount /mnt/postgres-nas
sudo mount -a
df -h /mnt/postgres-nas
```

## 4. Verify Storage Capacity

```bash
df -h
findmnt /mnt/postgres-nas
```

The additional NAS capacity should appear at `/mnt/postgres-nas`.

## 5. PostgreSQL Data Placement

**Do not move the active PostgreSQL data directory directly onto NFS.** Network storage latency, connectivity failures, permissions, and locking behavior can affect database reliability.

Recommended options:

- **Database storage:** Add a virtual disk to the PostgreSQL VM using Proxmox, backed by local storage or a supported NAS block-storage configuration.
- **Backups and exports:** Use the NFS mount at `/mnt/postgres-nas`.
- **Large files:** Store application files or database exports on NFS when appropriate.

To expand the PostgreSQL VM's actual database capacity, add a new virtual disk in Proxmox and configure its filesystem inside the VM.

## References

- [Synology NFS setup](https://kb.synology.com/en-sg/DSM/tutorial/how_to_set_up_Synology_NFS_share_as_Proxmox_storage)
- [Proxmox storage documentation](https://github.com/proxmox/pve-docs/blob/master/pvesm.adoc)

# Add Synology NAS as Proxmox NFS Storage

Configure Synology NAS as shared Proxmox storage for VM disks, container storage, backups, ISO images, templates, snippets and imported disk images. No iSCSI required.

## Environment

| Setting | Value |
|---|---|
| Synology NAS IP | `192.168.1.146` |
| Proxmox storage ID | `synology-nfs` |
| Example shared folder | `Proxmox` |
| Example NFS export | `/volume1/Proxmox` |
| Proxmox mount point | `/mnt/pve/synology-nfs` |

Replace the example export path with the actual path on your Synology NAS.

## 1. Configure Synology DSM

1. Open **Control Panel → File Services → NFS**.
2. Enable NFS.
3. Open **Control Panel → Shared Folder**.
4. Create a shared folder named `Proxmox`, or select an existing dedicated folder.
5. Edit the folder → **NFS Permissions → Create**.
6. Configure:
   - Hostname/IP: your Proxmox node IP.
   - Privilege: Read/Write.
   - Squash: No mapping, if required for VM disk access.
   - Security: `sys`.
   - Enable asynchronous access only if you accept the associated data-integrity risk.
7. Save the configuration and note the NFS export path.

Restrict NFS access to trusted Proxmox node IP addresses.

Reference: [Synology NFS setup for Proxmox](https://kb.synology.com/en-sg/DSM/tutorial/how_to_set_up_Synology_NFS_share_as_Proxmox_storage)

## 2. Verify the NFS Export

Run on the Proxmox node as root:

```bash
pvesm scan nfs 192.168.1.146
```

Confirm that the expected export appears in the output.

## 3. Add NFS Storage in Proxmox

In the Proxmox web interface:

1. Select **Datacenter → Storage → Add → NFS**.
2. Enter:

| Field | Value |
|---|---|
| ID | `synology-nfs` |
| Server | `192.168.1.146` |
| Export | `/volume1/Proxmox` |
| Content | Select the types required below |
| Nodes | Select your Proxmox node(s) |
| Enable | Enabled |
| NFS Version | `4.1`, if supported and enabled on Synology |

Select these content types as required:

- `Disk image` — VM virtual disks.
- `Container` — LXC container root filesystems.
- `Backup` — VM and container backups.
- `ISO image` — installation media.
- `Container template` — LXC templates.
- `Snippets` — cloud-init and hook scripts.
- `Import` — imported VM disk images.

Click **Add**.

Proxmox manages the NFS mount automatically at:

`/mnt/pve/synology-nfs`

## 4. Verify Storage

Run on the Proxmox node:

```bash
pvesm status
pvesm list synology-nfs
df -h /mnt/pve/synology-nfs
```

Confirm that the storage is active and reports the expected capacity.

## 5. Extend PostgreSQL VM Storage

To increase the storage available to PostgreSQL:

1. Open the PostgreSQL VM in Proxmox.
2. Select **Hardware → Add → Hard Disk**.
3. Select `synology-nfs` as the storage.
4. Specify the disk size and bus type.
5. Add the disk and boot the VM if required.
6. Inside the Debian/Ubuntu VM, identify the new disk:

```bash
lsblk
```

**Warning:** Verify the new disk device carefully before formatting. Formatting the wrong device destroys data.

Create a filesystem on the new disk, mount it, and configure `/etc/fstab` for persistence. To use it for PostgreSQL, stop PostgreSQL and migrate the database directory using a controlled migration procedure with correct ownership and permissions.

Keep a verified backup before migrating production data.

## 6. Important Storage Notes

- NFS is shared storage; Proxmox can use it for VM disks as well as backups and installation media.
- VM disk images on NFS use the network and depend on NAS availability. Database performance depends on NAS disks, network latency and workload.
- Proxmox supports snapshots and cloning for NFS-backed VM disks using supported image formats such as QCOW2; NFS itself does not provide native Proxmox snapshots.
- Do not configure the same NFS export as multiple independent Proxmox storage IDs.
- Use a separate backup policy. A VM disk stored on the NAS is not itself a backup.

## References

- [Proxmox NFS Storage Documentation](https://github.com/proxmox/pve-docs/blob/master/pve-storage-nfs.adoc)
- [Proxmox Storage Documentation](https://github.com/proxmox/pve-docs/blob/master/pvesm.adoc)
- [Synology NFS Configuration](https://kb.synology.com/en-sg/DSM/tutorial/how_to_set_up_Synology_NFS_share_as_Proxmox_storage)

