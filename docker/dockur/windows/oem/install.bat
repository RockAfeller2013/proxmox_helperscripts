@echo off

msiexec /q /i "C:\oem\data\sensor\installer_vista_win7_win8-64-4.1.0.5463.msi" /L* C:\oem\data\sensor\log.txt COMPANY_CODE=

# wusa "C:\oem\data\KB4474419\windows6.1-kb4474419-v3-x64_b5614c6cea5cb4e198717789633dca16308ef79c.msu" /quiet /norestart
# wmic computersystem where name="windows7A" call rename name="NewHostname"
# shutdown /r /t 0

# Windows 8.1 
# Install First https://www.microsoft.com/en-au/download/details.aspx?id=42327&utm_source=chatgpt.com
# Install Second https://www.microsoft.com/en-eg/download/details.aspx?id=44055&utm_source=chatgpt.com

# Activiate Windows
# slmgr /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# slmgr /ato
# slmgr /dlv > C:\oem\data\sensor\activation_log.txt

# Install Caldera Sandcat

powershell -ExecutionPolicy Bypass -Command "iex (iwr 'https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/main/docker/dockur/windows/oem/sandcat.ps1').Content"
