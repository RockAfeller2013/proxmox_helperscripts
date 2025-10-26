
[https://www.tracelabs.org/initiatives/osint-vm#downloads](https://github.com/tracelabs/tlosint-vm/releases)

https://www.tracelabs.org/initiatives/osint-vm

```
tar -xvf your_virtual_machine.ova
qemu-img convert -f vmdk -O qcow2 your_virtual_machine-disk001.vmdk output_image.qcow2
qemu-img info output_image.qcow2
Install sherlock
```
https://sherlockproject.xyz/

```
# Inside Kali (or your Debian-based VM)
cd ~/Desktop # or any folder you prefer

# Fetch the script (Raw URL) 
wget https://raw.githubusercontent.com/tracelabs/tlosint-vm/main/scripts/tlosint-tools.sh

# Give the script executable permission
chmod +x tlosint-tools.sh

#Execute the script
./tlosint-tools.sh
```
