# Auto installing Kali on Proxmox

- This scripts downloads the latest Kali QEMU image and deloys VM inside Proxmox, it then runs a Cloudint script to; Disable ipv6, Disable Firewall, Install Qemu Agent and configure RDP.

# DUFUK
After days testing cloud-init for kali, it seems for Desktop images that services is disabled. Go figure.. 

### Pre-made operating system images (especially ones designed for desktop use or specialized distros like Kali) have cloud-init disabled by default. This is because if it ran on a standard desktop install, it might try to re-configure the system on every boot, which isn't desired.

The main service that performs the initial configuration on first boot is called cloud-init.target or sometimes specific services like cloud-init-local.service.

## References
- Setting up RDP with Xfce - https://www.kali.org/docs/general-use/xfce-with-rdp/
- Kali inside Proxmox (Guest VM) - https://www.kali.org/docs/virtualization/install-proxmox-guest-vm/
- wget https://cdimage.kali.org/current/kali-linux-2025.2-installer-amd64.iso -O /var/lib/vz/template/iso/kali-linux-2025.2-installer-amd64.iso
- All cloud config examples - https://cloudinit.readthedocs.io/en/latest/reference/examples.html
- Kali In The Browser (noVNC) - https://www.kali.org/docs/general-use/novnc-kali-in-browser/
- Cloud-init not working with Kali image - https://www.reddit.com/r/Proxmox/comments/1gnbcaz/cloudinit_not_working_with_kali_image/


  
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/kali_install.sh)"
```

![hippo](https://media3.giphy.com/media/aUovxH8Vf9qDu/giphy.gif)
![til](https://raw.githubusercontent.com/hashrocket/hr-til/master/app/assets/images/banner.png)


# Test

![til](./app/assets/images/banner.png)

# SOLVED: I had to modify the initial qcow2 with virt-customize to run systemctl enable cloud-init-main

https://chat.deepseek.com/a/chat/s/0ef5f94d-d1f1-43af-bda1-b9196bb87b64

THe solution is to use a tool called virt-customize to "log into" the Kali Linux image file (qcow2) before uploading it to Proxmox and enabling a critical cloud-init service that was turned off.

The Detailed Explanation:

1. The Core Problem: Disabled Services
Many pre-made operating system images (especially ones designed for desktop use or specialized distros like Kali) have cloud-init disabled by default. This is because if it ran on a standard desktop install, it might try to re-configure the system on every boot, which isn't desired.

The main service that performs the initial configuration on first boot is called cloud-init.target or sometimes specific services like cloud-init-local.service.

2. The Symptom
When you upload an image where this service is disabled, here's what happens:

Proxmox creates the VM, attaches the cloud-init drive (containing your YAML config), and boots it.

The system boots normally.

Cloud-init never activates because its service is disabled. It doesn't check for the cloud-init drive, so it never sets the hostname, user, SSH keys, or password.

You're left with the default credentials and configuration of the original image.

3. The Solution: "Enabling the Service Inside the Image"
The user used virt-customize, a powerful command-line tool from the libguestfs project that lets you modify a virtual machine image without having to boot it up.

The command they likely ran looked something like this:

bash
virt-customize -a kali-linux-image.qcow2 --run-command "systemctl enable cloud-init.service cloud-init-local.service cloud-config.service cloud-final.service"
What this command does:

-a kali-linux-image.qcow2: Specifies the image file to modify.

--run-command "...": Executes a command inside the image's filesystem.

systemctl enable ...: This is the critical part. It enables the cloud-init services to start automatically on the next boot, just like you would if you were logged into a running system.

After this modification, the image is ready for Proxmox. On the first boot inside Proxmox, the cloud-init services will now start, see the configuration drive Proxmox attached, and apply your settings.

How to Do This Yourself (The Practical Steps)
Here is a step-by-step guide to implement this solution, which is more reliable than hoping the image works out-of-the-box.

Step 1: Install the required tools on your Proxmox server or any Linux machine.
```
bash
# On Debian/Ubuntu/Proxmox
apt update
apt install libguestfs-tools

# On Fedora/CentOS/RHEL
# dnf install libguestfs-tools
```
Step 2: Download your Kali (or any other) image.
```
bash
wget https://url-to-kali-image/kali-linux-rolling-qcow2-amd64.tar.xz
tar -xf kali-linux-rolling-qcow2-amd64.tar.xz
```
# You should now have a .qcow2 file
Step 3: Use virt-customize to enable cloud-init.
This is the most important step. Run a command like this:
```
bash
virt-customize -a ./kali-linux-2024.3-qemu-amd64.qcow2 \
    --update \
    --install cloud-init,cloud-guest-utils,cloud-initramfs-growroot \
    --run-command "systemctl enable cloud-init.service" \
    --run-command "systemctl enable cloud-init-local.service" \
    --run-command "systemctl enable cloud-config.service" \
    --run-command "systemctl enable cloud-final.service" \
    --run-command "sed -i 's/^disable_root:.*/disable_root: false/g' /etc/cloud/cloud.cfg" \
    --run-command "sed -i 's/^lock_passwd:.*/lock_passwd: false/g' /etc/cloud/cloud.cfg" \
    --ssh-inject kali:file:/path/to/your/public_ssh_key.pub \
    --root-password password:your_secure_temp_password
What this mega-command does:
```
--update: Updates the package list inside the image.

--install: Installs cloud-init and related utilities (in case they are missing!).

--run-command "systemctl enable ...": Enables the necessary services to start on boot.

--run-command "sed ...": (Optional but recommended) Edits the cloud-init config to allow root login and password authentication, which is often needed for the default kali user.

--ssh-inject: Injects your SSH public key for the kali user.

--root-password: Sets a temporary root password (often the default kali password is already set).

Step 4: Now upload this modified .qcow2 file to your Proxmox storage.
Proceed with creating your VM template from this image as you normally would. Now, when you deploy a VM from this template, cloud-init will actually run and apply your configuration.

# Eend

```
#cloud-config
hostname: kali-vm
fqdn: kali-vm.local
manage_etc_hosts: true

users:
  - name: kali
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...your-ssh-public-key-here...
    # Kali default user is 'kali' with password 'kali'
    # For security, you should change this or use SSH keys primarily

# Set password for the kali user (optional - use SSH keys for better security)
chpasswd:
  list: |
    kali:your-secure-password-here
  expire: false

# Enable password authentication for SSH (optional)
ssh_pwauth: true

# Update package cache and upgrade system on first boot
package_update: true
package_upgrade: true

# Install additional packages if needed
packages:
  - cloud-utils
  - cloud-initramfs-growroot

# Configure timezone
timezone: UTC

# Run commands on first boot
runcmd:
  - [systemctl, enable, --now, ssh]
  - [systemctl, restart, cloud-init]
  - [cloud-init, clean]
  - [cloud-init, init]

# Grow root partition to use all available space
growpart:
  mode: auto
  devices: ['/']

# Resize filesystem to use all available space
resize_rootfs: true

# Optional: Configure network (DHCP is usually fine)
# network:
#   version: 2
#   ethernets:
#     ens18:
#       dhcp4: true
```
