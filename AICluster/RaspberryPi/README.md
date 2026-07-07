# Raspberry PI 5 Setup

## Configure M.2

- https://chatgpt.com/c/6a462f66-ea08-83ec-a608-7b28b2565cbe

## Enable PCI
```
sudo rpi-eeprom-update
sudo rpi-update

raspi-config
Diable IPv6
Disable Wifi
Enable SSH
Enable RpiConnect

udo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean && sudo rpi-update &&  && sudo rpi-eeprom-update sudo reboot

```

```bash
sudo nano /boot/firmware/config.txt

[all]
dtparam=pciex1
dtparam=pciex1_gen=3  # optional
```

## Prepare NVMe

```bash
###############################################################################
# Display all storage devices with model and serial number.
# Verify that /dev/nvme0n1 is your M.2 NVMe SSD before making any changes.
###############################################################################
lsblk -o NAME,SIZE,MODEL,SERIAL

###############################################################################
# Display block devices, filesystems, UUIDs, labels, and mount points.
###############################################################################
lsblk -f

###############################################################################
# Update the package repository index.
###############################################################################
sudo apt update

###############################################################################
# Install PCI utilities (provides the lspci command).
###############################################################################
sudo apt install -y pciutils

###############################################################################
# List all PCI/PCIe devices.
# Verify that the NVMe controller is detected by the Raspberry Pi.
###############################################################################
lspci

###############################################################################
# Open the NVMe SSD in the fdisk partition editor.
# WARNING: The following steps will erase all existing data on the drive.
###############################################################################
sudo fdisk /dev/nvme0n1

# Inside fdisk, enter the following commands:
#
# g      -> Create a new GPT partition table (erases existing partitions)
# n      -> Create a new partition
# Enter  -> Accept default partition number
# Enter  -> Accept default first sector
# Enter  -> Accept default last sector (use entire disk)
# w      -> Write the partition table and exit

###############################################################################
# Format the new partition as an ext4 filesystem.
# WARNING: This permanently erases all data on the partition.
###############################################################################
sudo mkfs.ext4 /dev/nvme0n1p1

###############################################################################
# Create a mount point for the NVMe drive.
###############################################################################
sudo mkdir -p /mnt/nvme

###############################################################################
# Mount the NVMe partition.
###############################################################################
sudo mount /dev/nvme0n1p1 /mnt/nvme

###############################################################################
# Verify that the drive is mounted successfully and display disk usage.
###############################################################################
df -h

```

## Test LED
```bash

###############################################################################
# Display the UUIDs of all storage devices.
# Copy the UUID of the NVMe partition (e.g. /dev/nvme0n1p1).
###############################################################################
sudo blkid

###############################################################################
# Edit the filesystem table (fstab).
# This file controls which filesystems are mounted automatically at boot.
###############################################################################
sudo nano /etc/fstab

###############################################################################
# Add the following line to the end of the file.
#
# Replace <uuid> with the UUID obtained from the 'sudo blkid' command.
#
# Example:
# UUID=12345678-90ab-cdef-1234-567890abcdef /mnt/nvme ext4 defaults,noatime 0 2
#
# Field descriptions:
#   UUID=<uuid>   - Unique identifier of the partition
#   /mnt/nvme     - Mount point
#   ext4          - Filesystem type
#   defaults      - Standard mount options
#   noatime       - Improves performance by disabling access time updates
#   0             - Disable dump backups
#   2             - Check filesystem after the root filesystem during boot
###############################################################################
UUID=<uuid> /mnt/nvme ext4 defaults,noatime 0 2

###############################################################################
# Test the fstab configuration without rebooting.
# If no errors are displayed, the configuration is valid.
###############################################################################
sudo mount -a

###############################################################################
# Verify that the NVMe drive is mounted successfully.
###############################################################################
df -h
```

## Update

```bash

###############################################################################
# Change to the user's home directory.
# This ensures the DeskPi software is downloaded into the current user's folder.
###############################################################################
cd ~

###############################################################################
# Clone the DeskPi software repository from GitHub.
# This downloads the installation files required for DeskPi hardware support.
###############################################################################
git clone https://github.com/DeskPi-Team/deskpi.git

###############################################################################
# Navigate into the downloaded DeskPi software directory.
###############################################################################
cd ~/deskpi/

###############################################################################
# Make the installation script executable.
# This allows the install.sh file to be run as a program.
###############################################################################
chmod +x install.sh

###############################################################################
# Run the DeskPi installation script with administrator privileges.
# This installs the required drivers, services, and configuration files.
###############################################################################
sudo ./install.sh

```

## Install on NVMe

```bash
###############################################################################
# Install Raspberry Pi OS onto NVMe and boot Raspberry Pi 5 from NVMe SSD
###############################################################################

###############################################################################
# 1. Write Raspberry Pi OS to NVMe
#
# Install Raspberry Pi Imager:
###############################################################################

sudo apt install -y rpi-imager

###############################################################################
# Launch Raspberry Pi Imager:
###############################################################################

rpi-imager

###############################################################################
# In Raspberry Pi Imager select:
#
# Operating System:
#   Raspberry Pi OS (64-bit)
#
# Storage:
#   Select the NVMe drive
#
# This will create the required boot and root partitions:
#
# NVMe
# ├── nvme0n1p1  bootfs
# └── nvme0n1p2  rootfs
###############################################################################


###############################################################################
# 2. Enable NVMe boot support
#
# Check the current Raspberry Pi bootloader configuration:
###############################################################################

vcgencmd bootloader_config | grep BOOT_ORDER

###############################################################################
# Example output:
#
# BOOT_ORDER=0xf461
#
# The boot order determines which devices the Raspberry Pi checks during boot.
###############################################################################

###############################################################################
# Update the Raspberry Pi EEPROM bootloader:
###############################################################################

sudo rpi-eeprom-update -a

###############################################################################
# Reboot Raspberry Pi:
###############################################################################

sudo reboot


###############################################################################
# 3. Confirm NVMe is detected and being used
###############################################################################

lsblk

###############################################################################
# Expected output after booting from NVMe:
#
# nvme0n1
# ├─nvme0n1p1  /boot/firmware
# └─nvme0n1p2  /
###############################################################################


###############################################################################
# 4. Install DeskPi software after booting from NVMe
#
# The DeskPi installer installs hardware support software onto the current OS.
# Make sure the current OS is running from NVMe before running this.
###############################################################################

cd ~

###############################################################################
# Download DeskPi software:
###############################################################################

git clone https://github.com/DeskPi-Team/deskpi.git

###############################################################################
# Enter DeskPi installation directory:
###############################################################################

cd ~/deskpi

###############################################################################
# Make installation script executable:
###############################################################################

chmod +x install.sh

###############################################################################
# Run DeskPi installation:
###############################################################################

sudo ./install.sh


###############################################################################
# After installation:
#
# DeskPi software is now installed on the NVMe-based Raspberry Pi OS.
###############################################################################


###############################################################################
# Current system check:
#
# Current setup:
#
# USB 1.8TB SSD
# ├── bootfs
# └── rootfs  <-- Currently running OS
#
# NVMe M.2
# └── Unknown / not detected yet
###############################################################################


###############################################################################
# Check if the M.2 NVMe drive is detected before installing anything:
###############################################################################

lsblk -o NAME,SIZE,MODEL,SERIAL
```

## Verification

```

## Instal GPIZero

- gpiozero is a high-level Python library that makes it easy to control Raspberry Pi hardware such as:
- lgpio is the modern GPIO backend used by gpiozero on current Raspberry Pi OS releases.

```bash

10. Install GPIO Python libraries
sudo apt update
sudo apt install -y python3-gpiozero python3-rpi.gpio python3-lgpio

or via pip:

pip3 install gpiozero lgpio
11. UID LED Indicator (Raspberry Pi 5)

The Raspberry Pi 5 does not support the UID LED function found on some Raspberry Pi 4 expansion boards. If your NVMe HAT has its own UID LED, it will require the vendor's GPIO mapping and software.

12. CPU temperature

Current temperature:

vcgencmd measure_temp

Continuous monitoring:

watch -n1 vcgencmd measure_temp

Python:

from gpiozero import CPUTemperature

cpu = CPUTemperature()
print(cpu.temperature)
13. Install Sysbench
sudo apt update
sudo apt install -y sysbench

CPU benchmark:

sysbench cpu run

Memory benchmark:

sysbench memory run

File I/O benchmark:

sysbench fileio prepare
sysbench fileio run
sysbench fileio cleanup
14. Check if the NVMe drive is detected
ls /dev/nvme*
lsblk
lspci
dmesg | grep -Ei "nvme|pcie"
```

```bash
9. Disk speed test

Write test:

dd if=/dev/zero of=/mnt/nvme/test.img bs=1G count=1 oflag=direct

Read test:

dd if=/mnt/nvme/test.img of=/dev/null bs=1G

Delete test file:

rm /mnt/nvme/test.img
```


```
from gpiozero import LED
import time


uid_led = LED(4)

while True:
    uid_led.on()  # turn on led 
    time.sleep(5)
    uid_led.off() # turn off led 
    time.sleep(5)
```
```bash
sysbench fileio prepare
sysbench fileio run
sysbench fileio cleanup

lscpu | grep -i virtualization

egrep -c '(vmx|svm)' /proc/cpuinfo
lscpu | grep -i virtualization
sudo apt install -y cpu-checker
kvm-ok
```
- https://deskpi.com/blogs/learn/getting-start-how-to-install-deskpi-driver
- https://wiki.52pi.com/index.php?title=EP-0234
- https://www.youtube.com/watch?v=ZpW4YHlEElo
- https://wiki.52pi.com/index.php?title=EP-0234
- https://wiki.52pi.com/index.php?title=DR-0002
