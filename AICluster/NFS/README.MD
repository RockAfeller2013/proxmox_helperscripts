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
