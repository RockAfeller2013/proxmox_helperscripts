# Unbuntu on Proxmox


Method 1: Unlocking the Keyring
This method involves creating a keyring that doesn't require a password, which allows the remote desktop to consistently use the same password. 
Open Password and Keys: Search for and open the "Password and Keys" application (also known as Seahorse). 
Change the Keyring Password: Right-click on the "Default" keyring in the left-hand panel and select "Change password". 
Blank the Password: Enter your current user password when prompted, and then press Enter three times for the new password fields, leaving them blank. 
Accept the Warning: You will receive a warning about leaving the keyring unencrypted; accept this to proceed. 
Restart and Set Password: Reboot the computer, then go back into the remote desktop settings and set your desired password. This password will now remain the same after rebootin

Using Ubuntu Autoinstall with Cloud-Init\
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

## Proxmox Automation Tools

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
