# Ubuntu on Proxmox


- Use ubuntu-desktop.sh to install Unbuntu Desktop. FYI, Proxmox Helper scripts dont have a Desktop version. 
- Enable RDP via the GUI, the command lines don't work and I just don't care, just build a template and use that. I don't need to solve this problem right now.
- Enable SSH, Install QEMU Guest Tools, Disable Firewall
  
```bash
sudo ufw disable
sudo apt update
sudo apt install ssh
sudo apt install curl
sudo apt install net-tools
sudo apt install qemu-guest-agent
sudo apt update
sudo apt install -y ansible

```
- Disable IPV6

```bash
echo "Disabling IPv6..."

sudo tee /etc/sysctl.d/10-disable-ipv6.conf > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
```
```
wget -qO- https://omakub.org/install | bash

```
- Convert to a Template
## Unlocking the Keyring


This method involves creating a keyring that doesn't require a password, which allows the remote desktop to consistently use the same password. 
Open Password and Keys: Search for and open the "Password and Keys" application (also known as Seahorse). 

Change the Keyring Password: Right-click on the "Default" keyring in the left-hand panel and select "Change password". 
Blank the Password: Enter your current user password when prompted, and then press Enter three times for the new password fields, leaving them blank. 

Accept the Warning: You will receive a warning about leaving the keyring unencrypted; accept this to proceed. 
Restart and Set Password: Reboot the computer, then go back into the remote desktop settings and set your desired password. This password will now remain the same after rebootin

## Proxmox Automation Tools
### Using Ubuntu Autoinstall with Cloud-Init\
This approach automates the installation process itself.

1.  Download a Cloud-Init ISO image for Ubuntu.\
2.  Create an autoinstall configuration file (YAML) to define all the
    settings for the Ubuntu installation, such as language, user
    accounts, and network configuration.\
3.  Use subiquity (Ubuntu's installer) to generate a Cloud-Init ISO from
    your autoinstall configuration file.\
4.  Create a new VM in Proxmox, attach the Ubuntu installation ISO and
    the generated Cloud-Init ISO, and start the VM. The installation
    will be fully automated using the provided configuration.


Beyond Packer and Cloud-Init, you can also use other tools for more
advanced automation.

-   **Proxmox API & Scripts**: You can use the Proxmox API with scripts
    to automate the creation of VMs from your customized templates and
    manage them across your Proxmox cluster.\
-   **Cloud-init**: Proxmox has native support for Cloud-init, which can
    be integrated with templates to customize VMs upon first boot,
    allowing for per-VM specific configurations during cloning.

## References

-   https://github.com/Terraform-for-Proxmox/terraform-provider-proxmox\
-   https://kenbinlab.com/how-to-install-ubuntu-server-on-proxmox/\
-   https://youtu.be/zAPifhcA-Lg?si=FjonAw9IWpehGDby\
-   https://forum.proxmox.com/threads/full-automated-ubuntu-installation.91671/
-   https://github.com/community-scripts/ProxmoxVE/discussions/272
-   https://www.reddit.com/r/Ubuntu/comments/1sgk3ax/how_to_enable_rdp_remote_login_headless_mode_with/
-   https://claude.ai/chat/9494653e-01e7-46ee-80fc-998eec015148
-   https://aioue.net/2026/01/21/gnome-remote-desktop-rdp-ubuntu-24.04/
