- https://forums.raspberrypi.com/viewtopic.php?t=151302
- https://warmestrobot.com/blog/2024/06/27/raspberry-pi-network-boot-guide-2/

# Raspberry Pi iSCSI Network Boot Guide

Setting up an iSCSI network boot on a Raspberry Pi allows the device to run completely diskless without an SD card or local USB storage. This configuration is supported on models like the **Raspberry Pi 3B, 3B+, 4B, and 5**.

---

## 🛠️ Core Components Needed

*   **Client:** Raspberry Pi with network boot enabled in its EEPROM (`BOOT_ORDER`).
*   **DHCP / TFTP Server:** A service like `dnsmasq` to assign IP addresses and serve early boot files.
*   **NFS Server:** Shares the `/boot/firmware` (or `/boot`) directory so the Pi can load its kernel, device tree, and firmware.
*   **iSCSI Target/LUN:** Hosted on a network-attached storage (NAS) device, Proxmox, or a Linux server providing an ext4-formatted block device as the root filesystem.

---

## 🚀 Step-by-Step Instructions

### 1. Update EEPROM & Boot Order
Configure the Raspberry Pi's internal bootloader to prioritize network (PXE) booting. You can do this via `raspi-config` or network boot flash images to modify the `BOOT_ORDER` variable.

### 2. Configure the Network Server
Set up a `dnsmasq` server to provide Proxy DHCP and TFTP functionalities. Additionally, configure an NFS share to host the files from your boot partition.

### 3. Build the iSCSI Target & LUN
Create a Logical Unit Number (LUN) on your target server, format it as `ext4`, and copy the Raspberry Pi root filesystem (`rootfs`) into it. Use `rsync` while excluding virtual and mount directories like:
*   `/proc`
*   `/sys`
*   `/dev`
*   `/boot`

### 4. Configure Initramfs & Command Line
Build a custom `initramfs` image that includes `open-iscsi` support so the kernel can connect to the target during early boot. Update `cmdline.txt` to pass the iSCSI initiator/target parameters, network configurations, and the root UUID.

### 5. Update Fstab
Set up `/etc/fstab` on the iSCSI root volume to properly mount your partitions. Set the root volume to mount via iSCSI and `/boot/firmware` to mount via NFS. Ensure you use the `_netdev` option to prevent the system from mounting them before the network interface is up.

---

## 🔗 Useful Resources

*   **Detailed Guide:** [Raspberry Pi Network Boot Guide 2.0](https://warmestrobot.com)
