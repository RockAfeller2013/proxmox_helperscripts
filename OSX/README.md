# How to download and install macOS on Promox
- How to download and install macOS - http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg
- How to download and install macOS - https://support.apple.com/en-au/102662
- OSX-PROXMOX - https://github.com/luchina-gabriel/OSX-PROXMOX
- OSX-KVM - https://github.com/kholia/OSX-KVM
- Emulating MIPS guests in Proxmox 8 - https://www.nicksherlock.com/
- How to run the Installation offline without macOS - https://github.com/kholia/OSX-KVM/blob/master/run_offline.md
- https://github.com/kholia/OSX-KVM/blob/master/run_offline.md - https://github.com/nocontent06/OSX-Z
- McTwist - https://git.aposoc.net/McTwist/docker-files/src/branch/main/osx-cross.dockerfile

- Running a MacOS 15 Sequoia VM in Proxmox VE - https://www.youtube.com/watch?v=ApldztEgh8o


### Download MacOS OSX Sonoma for Intel and create a ISO

```

# 1. Download installer DMG
curl -O http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg

# 2. Mount the DMG
hdiutil attach InstallOS.dmg

# 3. Create a temporary empty image
hdiutil create -o /tmp/Sonoma -size 15000m -layout SPUD -fs HFS+J

# 4. Mount the temporary image
hdiutil attach /tmp/Sonoma.dmg -noverify -mountpoint /Volumes/Sonoma

# 5. Copy installer contents
rsync -av /Volumes/InstallOS/ /Volumes/Sonoma/

# 6. Detach both
hdiutil detach /Volumes/InstallOS
hdiutil detach /Volumes/Sonoma

# 7. Convert to ISO
hdiutil convert /tmp/Sonoma.dmg -format UDTO -o /tmp/Sonoma.iso

# 8. Rename to .iso
mv /tmp/Sonoma.iso.cdr ~/Desktop/Sonoma.iso

```


```
# Download specific version (if available)
softwareupdate --fetch-full-installer --full-installer-version 14.1.1

# Download latest version
softwareupdate --fetch-full-installer --latest

# Set download directory
softwareupdate --fetch-full-installer --volume /path/to/volume
```
```
# 1. First, download macOS Sonoma from App Store
softwareupdate --fetch-full-installer


#    Search "macOS Sonoma" in App Store and download

# 2. Create ISO from the installer
sudo /Applications/Install\ macOS\ Sonoma.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume

# Alternative method using hdiutil:
hdiutil create -o /tmp/Sonoma.cdr -size 16g -layout SPUD -fs HFS+J
hdiutil attach /tmp/Sonoma.cdr.dmg -noverify -mountpoint /Volumes/install_build
sudo /Applications/Install\ macOS\ Sonoma.app/Contents/Resources/createinstallmedia --volume /Volumes/install_build --nointeraction
hdiutil detach /Volumes/Install\ macOS\ Sonoma
hdiutil convert /tmp/Sonoma.cdr.dmg -format UDTO -o ~/Desktop/Sonoma
mv ~/Desktop/Sonoma.cdr ~/Desktop/Sonoma.iso
```


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


```


```
curl -O https://raw.githubusercontent.com/munki/macadmin-scripts/main/installinstallmacos.py
chmod +x installinstallmacos.py
sudo ./installinstallmacos.py
```
