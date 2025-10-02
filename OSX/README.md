# How to download and install macOS on Promox
- How to download and install macOS - http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg
- How to download and install macOS - https://support.apple.com/en-au/102662
- OSX-PROXMOX - https://github.com/luchina-gabriel/OSX-PROXMOX
- OSX-KVM - https://github.com/kholia/OSX-KVM
- Emulating MIPS guests in Proxmox 8 - https://www.nicksherlock.com/
- How to run the Installation offline without macOS - https://github.com/kholia/OSX-KVM/blob/master/run_offline.md
- https://github.com/kholia/OSX-KVM/blob/master/run_offline.md - https://github.com/nocontent06/OSX-Z
- McTwist - https://git.aposoc.net/McTwist/docker-files/src/branch/main/osx-cross.dockerfile
- https://github.com/munki/macadmin-scripts/tree/main

- Running a MacOS 15 Sequoia VM in Proxmox VE - https://www.youtube.com/watch?v=ApldztEgh8o

### First, download latest macOS Sonoma from App Store

```
# 1. First, download macOS Sonoma from App Store
softwareupdate --fetch-full-installer
softwareupdate --fetch-full-installer --full-installer-version 14.1.1
softwareupdate --fetch-full-installer --latest
softwareupdate --fetch-full-installer --volume /path/to/volume

# Direct Download
curl -O http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg


# Create a bootable installer for macOS - https://support.apple.com/en-us/101578

hdiutil convert nstallOS.dmg -format UDTO -o InstallOS.iso
mv InstallOS.iso.cdr InstallOS.iso
hdiutil info
hdiutil detach /Volumes/Install\ macOS   -force
hdiutil eject /Volumes/Install\ macOS



```
```
curl -O https://github.com/thenickdude/KVM-Opencore/releases/download/v21/OpenCore-v21.iso.gz
```


### Use this script
```
# Download the script
curl -O https://raw.githubusercontent.com/munki/macadmin-scripts/main/installinstallmacos.py

# Make executable
chmod +x installinstallmacos.py


# List available versions without downloading
./installinstallmacos.py --list

# Download specific version by product ID
./installinstallmacos.py --raw --version 14.1.1

# Set output directory
./installinstallmacos.py --workdir /path/to/downloads

curl -O https://raw.githubusercontent.com/munki/macadmin-scripts/main/installinstallmacos.py
chmod +x installinstallmacos.py
sudo ./installinstallmacos.py
```



### Usage: softwareupdate

```
usage: softwareupdate <cmd> [<args> ...]

** Manage Updates:
	-l | --list		List all appropriate update labels (options:  --no-scan, --product-types)
	-d | --download		Download Only
	-i | --install		Install
		<label> ...	specific updates
		-a | --all		All appropriate updates
		-R | --restart		Automatically restart (or shut down) if required to complete installation.
		-r | --recommended	Only recommended updates
		     --os-only	Only OS updates
		     --safari-only	Only Safari updates
		     --stdinpass	Password to authenticate as an owner. Apple Silicon only.
		     --user	Local username to authenticate as an owner. Apple Silicon only.
	--list-full-installers		List the available macOS Installers
	--fetch-full-installer		Install the latest recommended macOS Installer
		--full-installer-version	The version of macOS to install. Ex: --full-installer-version 10.15
	--install-rosetta	Install Rosetta 2
	--background		Trigger a background scan and update operation

** Other Tools:
	--dump-state		Log the internal state of the SU daemon to /var/log/install.log
	--evaluate-products	Evaluate a list of product keys specified by the --products option 
	--history		Show the install history.  By default, only displays updates installed by softwareupdate.  

** Options:
	--no-scan		Do not scan when listing or installing updates (use available updates previously scanned)
	--product-types <type>		Limit a scan to a particular product type only - ignoring all others
		Ex:  --product-types macOS  || --product-types macOS,Safari 
	--products		A comma-separated (no spaces) list of product keys to operate on. 
	--force			Force an operation to complete.  Use with --background to trigger a background scan regardless of "Automatically check" pref 
	--agree-to-license		Agree to the software license agreement without user interaction.

	--verbose		Enable verbose output
	--help			Print this help
```


### Download OpenCore
```
curl -L -o OpenCore-v21.iso.gz https://github.com/thenickdude/KVM-Opencore/releases/download/v21/OpenCore-v21.iso.gz
gunzip OpenCore-v21.iso


Once you get to the stage where you have to "nano /etc/pve/qemu-server/1500.conf"

1. DO NOT delete media=cdrom on both entries. 
2. Change media=cdrom to media=disk
3. add "cache=unsafe" after media=disk
4. Should look like this media=disk,chache=unsafe
5. Do this to both entries
Save changes and exit

For those whose installation gets stuck at the Apple logo, they should use this method: When creating a VM, set it up with 6 cores and 8GB of RAM. Start the VM, and if it gets stuck at the Apple logo, stop the VM, reduce it to 2 cores and 4GB of RAM, and then start it again. This should resolve your issue


For those whose installation gets stuck at the Apple logo, they should use this method: When creating a VM, set it up with 6 cores and 8GB of RAM. Start the VM, and if it gets stuck at the Apple logo, stop the VM, reduce it to 2 cores and 4GB of RAM, and then start it again. This should resolve your issue

8



```

### Setup Proxmox just for MacOS

```
curl -k -L -o proxmox-ve-8.4.iso "https://download.proxmox.com/iso/proxmox-ve_8.4-1.iso"


qm create 110 --name MacOSX --description "" --boot "order=ide2;scsi0" --cores 16 --cpu host --machine q35 --bios ovmf --ide2 local:iso/proxmox-ve-8.4.iso,media=cdrom --memory 32768 --net0 virtio,bridge=vmbr0,firewall=1 --numa 0 --ostype l26 --scsi0 local-lvm:60,iothread=1 --scsihw virtio-scsi-single --sockets 1 --efidisk0 local-lvm:1,efitype=4m,format=raw --bootdisk scsi0 --agent enabled=1

```
