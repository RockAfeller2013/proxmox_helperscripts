# Raspberry PI 5 Setup

## Configure M.2

- https://chatgpt.com/c/6a462f66-ea08-83ec-a608-7b28b2565cbe

```bash
boot/firmware/config.txt file and adding following parameter:
dtparam=pciex1
dtparam=pciex1_gen=3  # optional
```

```bash
lsblk -f

sudo apt update
sudo apt install -y pciutils

lspci

sudo fdisk /dev/nvme0n1

Inside fdisk:

g
n
Enter
Enter
Enter
w

sudo mkfs.ext4 /dev/nvme0n1p1

sudo mkdir -p /mnt/nvme
sudo mount /dev/nvme0n1p1 /mnt/nvme
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
- https://deskpi.com/blogs/learn/getting-start-how-to-install-deskpi-driver
- https://wiki.52pi.com/index.php?title=EP-0234
- https://www.youtube.com/watch?v=ZpW4YHlEElo
