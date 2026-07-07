# Raspberry PI 5 Setup

## Configure M.2

- https://chatgpt.com/c/6a462f66-ea08-83ec-a608-7b28b2565cbe

## Enable PCI

```bash
nano boot/firmware/config.txt file and adding following parameter:
dtparam=pciex1
dtparam=pciex1_gen=3  # optional
```

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

```bash
Automatically mount at boot

Find the UUID:

sudo blkid

Edit fstab:

sudo nano /etc/fstab

Add:

UUID=<uuid> /mnt/nvme ext4 defaults,noatime 0 2

Test:

sudo mount -a
```

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
For Raspbian and RetroPie OS.
cd ~
git clone https://github.com/DeskPi-Team/deskpi.git
cd ~/deskpi/
chmod +x install.sh
sudo ./install.sh
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
