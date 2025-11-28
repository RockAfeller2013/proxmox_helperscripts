# How to build Windows Server 2022 Datacentre with Desktop Expereince on Proxmox

- Build use the SERVER_EVAL_x64FRE_en-US.iso
- Enable Remote Desktop and add Administrators to users group
- Connect using RDP (Don't sellect Restricted Mode.)
- Install Updates
- Disable Firewall and Defender
- setup License
- Create template
```
DISM /online /Get-CurrentEdition
DISM /online /Get-TargetEditions
DISM /online /Set-Edition:ServerStandard /ProductKey:<YOUR-KEY> /AcceptEula

````
