#!/usr/bin/env bash

# Sophos Firewall VM Deployment Script for Proxmox VE
# Supports both Commercial and Home Edition deployments
# Home Edition: https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition
# Commercial: https://docs.sophos.com/nsg/sophos-firewall/
# Style inspired by: https://community-scripts.github.io/ProxmoxVE/scripts
#
# Home Edition Limitations:
# - Maximum 4 CPU cores (hardware can have more, but only 4 will be used)
# - Maximum 6GB RAM (hardware can have more, but only 6GB will be used)
# - Free for home use (no license required)
# - Community support only
#
# Installation Methods:
# 1. ISO method - Software Installer ISO (recommended for Home Edition)
# 2. QCOW2 method - KVM virtual disks (for commercial licenses only)

# Color codes
YW='\033[33m'
RD='\033[01;31m'
GN='\033[1;92m'
CL='\033[m'
BL='\033[36m'
BFR="\\r\\033[K"
HOLD="-"

# Error handling
set -euo pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR
trap cleanup EXIT

function error_exit() {
  trap - ERR
  local DEFAULT='Unknown failure occured.'
  local REASON="\e[97m${1:-$DEFAULT}\e[39m"
  local FLAG="\e[91m[ERROR] \e[93m$EXIT@$LINE"
  msg "$FLAG $REASON"
  exit $EXIT
}

function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

function cleanup() {
  popd >/dev/null 2>&1 || true
  rm -rf $TEMP_DIR
}

function header_info() {
  clear
  cat <<"EOF"
   _____             __                   ________                      ____
  / ___/____  ____  / /_  ____  _____   / ____(_)_______   ____  ____ _/ / /
  \__ \/ __ \/ __ \/ __ \/ __ \/ ___/  / /_  / / ___/ _ \ / __ \/ __ `/ / / 
 ___/ / /_/ / /_/ / / / / /_/ (__  )  / __/ / / /  /  __// /_/ / /_/ / / /  
/____/\____/ .___/_/ /_/\____/____/  /_/   /_/_/   \___/ \____/\__,_/_/_/   
          /_/                                                                
                    Proxmox VE Deployment Script
EOF
}

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${GN}✓${CL} ${GN}${msg}${CL}"
}

function msg_error() {
  local msg="$1"
  echo -e "${BFR} ${RD}✗${CL} ${RD}${msg}${CL}"
}

function pve_check() {
  if ! pveversion | grep -Eq "pve-manager/(8\.[1-9]|[9-9]\.)"; then
    msg_error "This script requires Proxmox Virtual Environment 8.1 or greater"
    msg_error "Exiting..."
    sleep 2
    exit
  fi
}

function ssh_check() {
  if command -v pveversion >/dev/null 2>&1; then
    if [ -n "${SSH_CLIENT:+x}" ]; then
      if whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "SSH DETECTED" --yesno "It's suggested to use the Proxmox shell instead of SSH, since SSH can create issues while gathering variables. Would you like to proceed with using SSH?" 10 62; then
        echo "you've been warned"
      else
        clear
        exit
      fi
    fi
  fi
}

function arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    msg_error "This script will not work with PiMox! \n"
    msg_error "Exiting..."
    sleep 2
    exit
  fi
}

# Set default variables
VMID=""
VM_NAME="sophos-firewall"
CORES="2"
RAM="4096"
BRIDGE="vmbr0"
BRIDGE2="vmbr1"
MACHINE="q35"
STORAGE="local-lvm"
STORAGE_TYPE=""
INSTALL_METHOD=""
LICENSE_TYPE=""
DOWNLOAD_PATH=""
ISO_PATH=""

function default_settings() {
  VMID=$(pvesh get /cluster/nextid)
  echo -e "${BL}Using Default Settings${CL}"
  echo -e "${GN}VM ID: ${VMID}${CL}"
  echo -e "${GN}VM Name: ${VM_NAME}${CL}"
  echo -e "${GN}CPU Cores: ${CORES}${CL}"
  echo -e "${GN}RAM: ${RAM}MB${CL}"
  echo -e "${GN}Primary Bridge: ${BRIDGE}${CL}"
  echo -e "${GN}Secondary Bridge: ${BRIDGE2}${CL}"
  echo -e "${GN}Machine Type: ${MACHINE}${CL}"
  echo -e "${GN}Storage: ${STORAGE}${CL}"
}

function advanced_settings() {
  VMID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set VM ID" 8 58 $(pvesh get /cluster/nextid) --title "VM ID" 3>&1 1>&2 2>&3)
  if [ -z "$VMID" ]; then
    VMID="$(pvesh get /cluster/nextid)"
    echo -e "${BL}Using Default VM ID: ${VMID}${CL}"
  fi
  
  VM_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set VM Name" 8 58 "$VM_NAME" --title "VM NAME" 3>&1 1>&2 2>&3)
  if [ -z "$VM_NAME" ]; then
    VM_NAME="sophos-firewall"
    echo -e "${BL}Using Default VM Name: ${VM_NAME}${CL}"
  fi
  
  if [ "$LICENSE_TYPE" == "home" ]; then
    # Home Edition limits
    CORES="4"
    RAM="6144"
    echo -e "${YW}Home Edition is limited to 4 cores and 6GB RAM${CL}"
    echo -e "${BL}CPU Cores: ${CORES} (Home Edition Maximum)${CL}"
    echo -e "${BL}RAM: ${RAM}MB (Home Edition Maximum)${CL}"
  else
    # Commercial license - allow customization
    CORES=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 2 --title "CORE COUNT" 3>&1 1>&2 2>&3)
    if [ -z "$CORES" ]; then
      CORES="2"
      echo -e "${BL}Using Default CPU Cores: ${CORES}${CL}"
    fi
    
    RAM=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MB (Minimum 4096)" 8 58 4096 --title "RAM" 3>&1 1>&2 2>&3)
    if [ -z "$RAM" ]; then
      RAM="4096"
      echo -e "${BL}Using Default RAM: ${RAM}MB${CL}"
    fi
  fi
  
  BRIDGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Primary Network Bridge (WAN)" 8 58 vmbr0 --title "BRIDGE" 3>&1 1>&2 2>&3)
  if [ -z "$BRIDGE" ]; then
    BRIDGE="vmbr0"
    echo -e "${BL}Using Default Primary Bridge: ${BRIDGE}${CL}"
  fi
  
  BRIDGE2=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Secondary Network Bridge (LAN)" 8 58 vmbr1 --title "BRIDGE 2" 3>&1 1>&2 2>&3)
  if [ -z "$BRIDGE2" ]; then
    BRIDGE2="vmbr1"
    echo -e "${BL}Using Default Secondary Bridge: ${BRIDGE2}${CL}"
  fi
  
  MACHINE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Machine Type" 8 58 q35 --title "MACHINE TYPE" 3>&1 1>&2 2>&3)
  if [ -z "$MACHINE" ]; then
    MACHINE="q35"
    echo -e "${BL}Using Default Machine Type: ${MACHINE}${CL}"
  fi
  
  STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Storage Location" 8 58 local-lvm --title "STORAGE" 3>&1 1>&2 2>&3)
  if [ -z "$STORAGE" ]; then
    STORAGE="local-lvm"
    echo -e "${BL}Using Default Storage: ${STORAGE}${CL}"
  fi
}

function start_script() {
  if [ -z "$ADVANCED" ]; then
    if whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58; then
      header_info
      echo -e "${BL}Using Default Settings${CL}"
      default_settings
    else
      header_info
      echo -e "${BL}Using Advanced Settings${CL}"
      advanced_settings
    fi
  fi
}

function get_storage_type() {
  STORAGE_TYPE=$(pvesm status -storage $STORAGE | awk 'NR>1 {print $2}')
}

function choose_license_type() {
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "LICENSE TYPE" --yesno "Choose your Sophos Firewall license type:\n\nHOME EDITION (Free):\n- Free for home use\n- Limited to 4 CPU cores\n- Limited to 6GB RAM\n- Community support only\n- No license key required\n- ISO installation only\n\nCOMMERCIAL LICENSE:\n- Requires valid license/subscription\n- No CPU/RAM limitations\n- Full Sophos support\n- QCOW2 or ISO installation\n\nAre you using HOME EDITION?" --yes-button "Home Edition" --no-button "Commercial" 22 70); then
    LICENSE_TYPE="home"
    echo -e "${GN}License Type: HOME EDITION (Free)${CL}"
    echo -e "${YW}Note: Home Edition limited to 4 cores and 6GB RAM${CL}"
    # Force ISO method for Home Edition
    INSTALL_METHOD="iso"
    # Enforce Home Edition limits
    CORES="4"
    RAM="6144"
  else
    LICENSE_TYPE="commercial"
    echo -e "${GN}License Type: COMMERCIAL${CL}"
  fi
}

function choose_install_method() {
  if [ "$LICENSE_TYPE" == "home" ]; then
    # Home Edition only supports ISO
    INSTALL_METHOD="iso"
    echo -e "${BL}Home Edition uses ISO installation method${CL}"
    return
  fi
  
  # Commercial license can choose
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "INSTALLATION METHOD" --yesno "Choose installation method:\n\nQCOW2 Method (Recommended):\n- Faster deployment\n- Pre-configured disks\n- Download: Virtual Installers for KVM (VI-*.KVM-*.zip)\n\nISO Method:\n- Traditional installation\n- More control over disk configuration\n- Download: Software ISO (SW-*.iso)\n\nUse QCOW2 method?" --yes-button "QCOW2" --no-button "ISO" 18 70); then
    INSTALL_METHOD="qcow2"
  else
    INSTALL_METHOD="iso"
  fi
  echo -e "${GN}Installation Method: ${INSTALL_METHOD^^}${CL}"
}

function download_sophos_qcow2() {
  msg_info "QCOW2 method requires KVM Virtual Installer ZIP file"
  echo ""
  echo -e "${YW}Download Instructions:${CL}"
  echo -e "1. Visit: ${BL}https://www.sophos.com/en-us/support/downloads/firewall-installers${CL}"
  echo -e "2. Look for: ${GN}Virtual Installers: Firewall OS for KVM${CL}"
  echo -e "3. Download the ZIP file (e.g., VI-21.5.0_GA.KVM-171.zip)"
  echo ""
  
  DOWNLOAD_PATH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter the full path to the downloaded Sophos KVM ZIP file:\n\nExample: /root/VI-21.5.0_GA.KVM-171.zip" 12 78 --title "SOPHOS KVM ZIP FILE" 3>&1 1>&2 2>&3)
  
  if [ -z "$DOWNLOAD_PATH" ] || [ ! -f "$DOWNLOAD_PATH" ]; then
    msg_error "File not found: $DOWNLOAD_PATH"
    msg_error "Please download the KVM ZIP file and run the script again"
    exit 1
  fi
  
  msg_ok "Found Sophos KVM ZIP file"
}

function download_sophos_iso() {
  if [ "$LICENSE_TYPE" == "home" ]; then
    msg_info "ISO method for HOME EDITION"
    echo ""
    echo -e "${YW}Download Instructions for HOME EDITION:${CL}"
    echo -e "1. Visit: ${BL}https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition/software${CL}"
    echo -e "2. Click: ${GN}Download Now${CL}"
    echo -e "3. Download the Software ISO (e.g., SW-21.5.0_GA-171.iso)"
    echo -e "4. ${RD}No license key required${CL} for Home Edition"
    echo ""
  else
    msg_info "ISO method for COMMERCIAL LICENSE"
    echo ""
    echo -e "${YW}Download Instructions for COMMERCIAL:${CL}"
    echo -e "1. Visit: ${BL}https://www.sophos.com/en-us/support/downloads/firewall-installers${CL}"
    echo -e "2. Look for: ${GN}Software Installers: Firewall OS Software ISO for Intel Hardware${CL}"
    echo -e "3. Download the ISO file (e.g., SW-21.5.0_GA-171.iso)"
    echo -e "4. ${YW}You will need a valid license/serial number${CL}"
    echo ""
  fi
  
  ISO_PATH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter the full path to the downloaded Sophos Software ISO file:\n\nExample: /root/SW-21.5.0_GA-171.iso" 12 78 --title "SOPHOS SOFTWARE ISO" 3>&1 1>&2 2>&3)
  
  if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
    msg_error "File not found: $ISO_PATH"
    msg_error "Please download the Software ISO file and run the script again"
    exit 1
  fi
  
  msg_ok "Found Sophos Software ISO file"
}

function create_vm() {
  msg_info "Creating VM ${VMID}"
  
  if [ "$INSTALL_METHOD" == "qcow2" ]; then
    # QCOW2 method - create VM without any media
    qm create $VMID \
      --name $VM_NAME \
      --machine $MACHINE \
      --bios ovmf \
      --cores $CORES \
      --memory $RAM \
      --net0 virtio,bridge=$BRIDGE \
      --ostype l26 \
      --scsihw virtio-scsi-pci \
      --agent 0
  else
    # ISO method - create VM with ISO attached
    # First, upload ISO to Proxmox storage if not already there
    ISO_STORAGE="local"
    ISO_NAME=$(basename "$ISO_PATH")
    ISO_TARGET="/var/lib/vz/template/iso/$ISO_NAME"
    
    if [ ! -f "$ISO_TARGET" ]; then
      msg_info "Copying ISO to Proxmox ISO storage"
      cp "$ISO_PATH" "$ISO_TARGET"
      msg_ok "ISO copied to storage"
    fi
    
    qm create $VMID \
      --name $VM_NAME \
      --machine $MACHINE \
      --bios ovmf \
      --cores $CORES \
      --memory $RAM \
      --net0 virtio,bridge=$BRIDGE \
      --ostype l26 \
      --scsihw virtio-scsi-pci \
      --agent 0 \
      --ide2 $ISO_STORAGE:iso/$ISO_NAME,media=cdrom
    
    # Create disks for ISO installation
    qm set $VMID --scsi0 $STORAGE:32,format=qcow2
    qm set $VMID --scsi1 $STORAGE:80,format=qcow2
  fi
  
  msg_ok "VM ${VMID} created"
}

function extract_disks() {
  msg_info "Extracting Sophos QCOW2 disks"
  
  TEMP_DIR=$(mktemp -d)
  cd $TEMP_DIR
  
  unzip -q "$DOWNLOAD_PATH"
  
  PRIMARY_DISK=$(find . -name "*PRIMARY*.qcow2" | head -n 1)
  AUXILIARY_DISK=$(find . -name "*AUXILIARY*.qcow2" | head -n 1)
  
  if [ -z "$PRIMARY_DISK" ] || [ -z "$AUXILIARY_DISK" ]; then
    msg_error "Could not find PRIMARY or AUXILIARY disk in ZIP file"
    exit 1
  fi
  
  msg_ok "Disks extracted to temp directory"
}

function import_disks() {
  msg_info "Importing PRIMARY disk to VM ${VMID}"
  get_storage_type
  
  if [ "$STORAGE_TYPE" == "dir" ] || [ "$STORAGE_TYPE" == "nfs" ]; then
    STORAGE_PATH="/var/lib/vz"
    if pvesm path $STORAGE:0 >/dev/null 2>&1; then
      STORAGE_PATH=$(dirname $(pvesm path $STORAGE:0))
    fi
    DISK_DIR="$STORAGE_PATH/images/$VMID"
    mkdir -p $DISK_DIR
    
    cp "$PRIMARY_DISK" "$DISK_DIR/PRIMARY-DISK.qcow2"
    cp "$AUXILIARY_DISK" "$DISK_DIR/AUXILIARY-DISK.qcow2"
    
    qm set $VMID --scsi0 $STORAGE:$VMID/PRIMARY-DISK.qcow2
    qm set $VMID --scsi1 $STORAGE:$VMID/AUXILIARY-DISK.qcow2
  else
    qm importdisk $VMID "$PRIMARY_DISK" $STORAGE -format qcow2
    qm importdisk $VMID "$AUXILIARY_DISK" $STORAGE -format qcow2
    
    qm set $VMID --scsi0 $STORAGE:vm-$VMID-disk-0
    qm set $VMID --scsi1 $STORAGE:vm-$VMID-disk-1
  fi
  
  msg_ok "Disks imported successfully"
}

function configure_vm() {
  msg_info "Configuring VM settings"
  
  # Add second network interface
  qm set $VMID --net1 virtio,bridge=$BRIDGE2
  
  # Add EFI disk
  qm set $VMID --efidisk0 $STORAGE:1,efitype=4m,pre-enrolled-keys=0
  
  if [ "$INSTALL_METHOD" == "qcow2" ]; then
    # Set boot order for QCOW2 method
    qm set $VMID --boot order=scsi0
  else
    # Set boot order for ISO method (boot from CD first for installation)
    qm set $VMID --boot order=ide2\;scsi0
  fi
  
  # Disable QEMU Guest Agent (critical for Sophos Firewall)
  qm set $VMID --agent 0
  
  msg_ok "VM configuration completed"
}

function display_completion() {
  header_info
  echo ""
  msg_ok "Sophos Firewall VM Successfully Created!"
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${GN}VM ID:${CL} ${VMID}"
  echo -e "${GN}VM Name:${CL} ${VM_NAME}"
  echo -e "${GN}License Type:${CL} ${LICENSE_TYPE^^}"
  echo -e "${GN}Installation Method:${CL} ${INSTALL_METHOD^^}"
  echo -e "${GN}Cores:${CL} ${CORES}"
  echo -e "${GN}RAM:${CL} ${RAM}MB"
  echo -e "${GN}Primary Network:${CL} ${BRIDGE}"
  echo -e "${GN}Secondary Network:${CL} ${BRIDGE2}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo ""
  
  if [ "$LICENSE_TYPE" == "home" ]; then
    echo -e "${YW}Next Steps (HOME EDITION):${CL}"
    echo -e "1. Start the VM: ${GN}qm start ${VMID}${CL}"
    echo -e "2. Open the console: Proxmox UI → VM ${VMID} → Console"
    echo -e "3. Follow the installation wizard in the console"
    echo -e "4. ${GN}No license key required${CL} - select Home Edition during setup"
    echo -e "5. Set admin password during installation"
    echo -e "6. After installation completes, the VM will reboot"
    echo -e "7. Remove ISO from VM: ${GN}qm set ${VMID} --ide2 none${CL}"
    echo -e "8. Access web interface at: ${GN}https://172.16.16.16:4444${CL}"
    echo -e "9. Complete the Sophos Firewall setup wizard"
    echo ""
    echo -e "${BL}Home Edition Limitations:${CL}"
    echo -e "- Maximum 4 CPU cores (enforced by Sophos)"
    echo -e "- Maximum 6GB RAM (enforced by Sophos)"
    echo -e "- Community support only (no commercial support)"
    echo -e "- Free for home use - no subscription required"
  elif [ "$INSTALL_METHOD" == "qcow2" ]; then
    echo -e "${YW}Next Steps (QCOW2 Method):${CL}"
    echo -e "1. Start the VM: ${GN}qm start ${VMID}${CL}"
    echo -e "2. Wait 30-60 seconds for firewall to boot"
    echo -e "3. Access web interface at: ${GN}https://172.16.16.16:4444${CL}"
    echo -e "4. ${YW}Enter your license/serial number${CL} during setup"
    echo -e "5. Complete the Sophos Firewall setup wizard"
  else
    echo -e "${YW}Next Steps (ISO Method - Commercial):${CL}"
    echo -e "1. Start the VM: ${GN}qm start ${VMID}${CL}"
    echo -e "2. Open the console: Proxmox UI → VM ${VMID} → Console"
    echo -e "3. Follow the installation wizard in the console"
    echo -e "4. ${YW}Enter your license/serial number${CL} when prompted"
    echo -e "5. Select disk installation options during setup"
    echo -e "6. After installation completes, the VM will reboot"
    echo -e "7. Remove ISO from VM: ${GN}qm set ${VMID} --ide2 none${CL}"
    echo -e "8. Access web interface at: ${GN}https://172.16.16.16:4444${CL}"
    echo -e "9. Complete the Sophos Firewall setup wizard"
  fi
  
  echo ""
  echo -e "${YW}Important Notes:${CL}"
  echo -e "- ${RD}CRITICAL:${CL} QEMU Guest Agent is disabled (required for Sophos)"
  echo -e "- Default web interface: https://172.16.16.16:4444"
  echo -e "- Minimum 4GB RAM is required for optimal performance"
  echo -e "- Two network interfaces are configured (WAN/LAN)"
  if [ "$LICENSE_TYPE" == "home" ]; then
    echo -e "- ${GN}Support:${CL} https://community.sophos.com/sophos-xg-firewall/"
  fi
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo ""
}

# Main script execution
header_info
echo -e "\n Loading..."
pve_check
arch_check
ssh_check

# Choose license type first
choose_license_type

# Choose installation method (auto-selected for Home Edition)
choose_install_method

start_script

msg_info "Validating Storage"
get_storage_type
if [ "$STORAGE_TYPE" == "" ]; then
  msg_error "Invalid Storage: ${STORAGE}"
  exit 1
fi
msg_ok "Validated Storage"

# Download appropriate files based on method
if [ "$INSTALL_METHOD" == "qcow2" ]; then
  download_sophos_qcow2
  create_vm
  extract_disks
  import_disks
  configure_vm
  cleanup
else
  download_sophos_iso
  create_vm
  configure_vm
fi

display_completion
