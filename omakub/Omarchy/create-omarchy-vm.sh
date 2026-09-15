#!/usr/bin/env bash

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Omarchy unattended Proxmox VM installer
#
# Run this on the Proxmox host.
#
# Requirements:
#   - curl
#   - openssl
#   - xorriso
#   - qm
#   - pvesm
#
# Example:
#   sudo ./create-omarchy-vm.sh
#
# Optional environment variables:
#
#   VMID=120
#   VM_NAME=omarchy
#   STORAGE=local-lvm
#   ISO_STORAGE=local
#   DISK_SIZE=80
#   MEMORY=16384
#   CORES=8
#   BRIDGE=vmbr0
#   USERNAME=rock
#   FULL_NAME="Rock Ade"
#   GIT_EMAIL="user@example.com"
#   TIMEZONE=Australia/Brisbane
#   KEYBOARD=us
#   INSTALL_DISK=/dev/sda
#   ENABLE_SSH=true
#   ENABLE_TAILSCALE=false
#   TAILSCALE_AUTHKEY=
#   SSH_PUBLIC_KEY_FILE=$HOME/.ssh/id_ed25519.pub
#
# -----------------------------------------------------------------------------

OMARCHY_BASE_URL="https://iso.omarchy.org"
OMARCHY_VERSION="${OMARCHY_VERSION:-4.0.3}"
OMARCHY_ISO_NAME="omarchy-${OMARCHY_VERSION}.iso"

VMID="${VMID:-120}"
VM_NAME="${VM_NAME:-omarchy}"

STORAGE="${STORAGE:-local-lvm}"
ISO_STORAGE="${ISO_STORAGE:-local}"

# Proxmox's disk-allocation syntax for --scsiN/--virtioN is
# "<storage>:<size_in_GiB>" as a BARE INTEGER (e.g. "80"), not "80G".
# Strip a trailing G/g in case someone sets DISK_SIZE=80G anyway.
DISK_SIZE="${DISK_SIZE:-80}"
DISK_SIZE="${DISK_SIZE%%[Gg]}"

MEMORY="${MEMORY:-16384}"
CORES="${CORES:-8}"

BRIDGE="${BRIDGE:-vmbr0}"

USERNAME="${USERNAME:-}"
FULL_NAME="${FULL_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"

TIMEZONE="${TIMEZONE:-Australia/Brisbane}"
KEYBOARD="${KEYBOARD:-us}"

INSTALL_DISK="${INSTALL_DISK:-/dev/sda}"

ENABLE_SSH="${ENABLE_SSH:-true}"
ENABLE_TAILSCALE="${ENABLE_TAILSCALE:-false}"
TAILSCALE_AUTHKEY="${TAILSCALE_AUTHKEY:-}"

SSH_PUBLIC_KEY_FILE="${SSH_PUBLIC_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

WORK_DIR="${WORK_DIR:-/var/lib/vz/omarchy}"
ISO_DIR="$WORK_DIR/iso"
CIDATA_DIR="$WORK_DIR/cidata"
OUTPUT_DIR="$WORK_DIR/output"

OMARCHY_ISO="$ISO_DIR/$OMARCHY_ISO_NAME"
OMARCHY_SIG="$OMARCHY_ISO.sig"

# Per-VM filename so concurrent/repeated runs for different VMs don't
# clobber a shared "cidata.iso" in Proxmox storage.
CIDATA_ISO_NAME="cidata-$VMID.iso"
CIDATA_ISO="$OUTPUT_DIR/$CIDATA_ISO_NAME"

ISO_URL="$OMARCHY_BASE_URL/$OMARCHY_ISO_NAME"
SIG_URL="$ISO_URL.sig"

TMP_CHECKSUM="$WORK_DIR/omarchy.sha256"

cleanup() {
    rm -f "$TMP_CHECKSUM"
}

error_handler() {
    echo
    echo "ERROR: Installation preparation failed."
    echo "Line: $1"
    exit 1
}

trap 'error_handler $LINENO' ERR
trap cleanup EXIT


# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "ERROR: Run this script as root."
        echo
        echo "Example:"
        echo "  sudo $0"
        exit 1
    fi
}


require_tty() {
    # This script prompts for a password (and possibly an SSH key path
    # or Tailscale auth key). If it's run as "curl ... | bash", stdin is
    # the piped script itself, not your keyboard - every `read` below
    # would silently get an empty string instead of erroring, and you'd
    # end up with a VM whose password hash is just openssl passwd -6 ""
    # with no warning at all. Reading from /dev/tty instead means a
    # missing terminal fails loudly here rather than corrupting input
    # silently later.
    if [[ ! -r /dev/tty ]]; then
        echo "ERROR: No interactive terminal (/dev/tty) is available."
        echo
        echo "This script needs to prompt you for a password, so it"
        echo "can't be run as 'curl ... | bash'. Download it first,"
        echo "then run it directly:"
        echo
        echo "  curl -fsSL <raw-url> -o create-omarchy-vm.sh"
        echo "  chmod +x create-omarchy-vm.sh"
        echo "  sudo ./create-omarchy-vm.sh"
        exit 1
    fi
}


require_commands() {
    local commands=(
        curl
        openssl
        xorriso
        qm
        pvesm
        sha256sum
    )

    for command in "${commands[@]}"; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "ERROR: Required command not found: $command"
            exit 1
        fi
    done
}


prompt_configuration() {
    echo
    echo "=========================================="
    echo " Omarchy unattended Proxmox installation"
    echo "=========================================="
    echo

    if [[ -z "$USERNAME" ]]; then
        read -r -p "Omarchy username: " USERNAME < /dev/tty
    fi

    if [[ -z "$FULL_NAME" ]]; then
        read -r -p "Full name: " FULL_NAME < /dev/tty
    fi

    if [[ -z "$GIT_EMAIL" ]]; then
        read -r -p "Git email: " GIT_EMAIL < /dev/tty
    fi

    echo
    echo "VM configuration:"
    echo "  VMID:          $VMID"
    echo "  Name:          $VM_NAME"
    echo "  Storage:       $STORAGE"
    echo "  ISO storage:   $ISO_STORAGE"
    echo "  Disk:          ${DISK_SIZE}G"
    echo "  Memory:        ${MEMORY} MB"
    echo "  CPUs:          $CORES"
    echo "  Network:       $BRIDGE"
    echo "  Timezone:      $TIMEZONE"
    echo "  Keyboard:      $KEYBOARD"
    echo "  Install disk:  $INSTALL_DISK"
    echo "  SSH:           $ENABLE_SSH"
    echo "  Tailscale:     $ENABLE_TAILSCALE"
    echo
}


prepare_directories() {
    echo "==> Creating working directories"

    mkdir -p \
        "$ISO_DIR" \
        "$CIDATA_DIR" \
        "$OUTPUT_DIR"

    chmod 700 "$WORK_DIR"
}


download_iso() {
    echo
    echo "==> Downloading Omarchy $OMARCHY_VERSION"

    if [[ -f "$OMARCHY_ISO" ]]; then
        echo "ISO already exists:"
        echo "  $OMARCHY_ISO"
    else
        curl \
            --fail \
            --location \
            --progress-bar \
            --retry 5 \
            --retry-delay 3 \
            --continue-at - \
            --output "$OMARCHY_ISO" \
            "$ISO_URL"
    fi

    if [[ ! -s "$OMARCHY_ISO" ]]; then
        echo
        echo "ERROR: Omarchy ISO is missing or empty after download:"
        echo "  $OMARCHY_ISO"
        echo
        echo "Check free space on the volume backing WORK_DIR ($WORK_DIR)"
        echo "and that this host can reach $OMARCHY_BASE_URL, e.g.:"
        echo "  df -h $WORK_DIR"
        echo "  curl -Iv $ISO_URL"
        exit 1
    fi

    echo
    echo "ISO:"
    ls -lh "$OMARCHY_ISO"
}


verify_iso_checksum() {
    echo
    echo "==> Checking for published SHA-256 checksum"

    local checksum_urls=(
        "$OMARCHY_BASE_URL/$OMARCHY_ISO_NAME.sha256"
        "$OMARCHY_BASE_URL/$OMARCHY_ISO_NAME.sha256sum"
        "$OMARCHY_BASE_URL/SHA256SUMS"
        "$OMARCHY_BASE_URL/SHA256SUMS.txt"
    )

    local checksum_downloaded=false

    for url in "${checksum_urls[@]}"; do
        echo "Checking: $url"

        if curl \
            --fail \
            --silent \
            --show-error \
            --location \
            --output "$TMP_CHECKSUM" \
            "$url"; then

            checksum_downloaded=true
            echo "Found checksum:"
            cat "$TMP_CHECKSUM"
            break
        fi
    done

    if [[ "$checksum_downloaded" != true ]]; then
        echo
        echo "WARNING: No published SHA-256 checksum file was found."
        echo "The ISO will still be used."
        return 0
    fi

    local expected
    local actual

    expected="$(
        grep -E \
            "(^|[[:space:]])${OMARCHY_ISO_NAME}([[:space:]]|$)" \
            "$TMP_CHECKSUM" \
            | head -n 1 \
            | awk '{print $1}'
    )"

    if [[ -z "$expected" ]]; then
        expected="$(
            grep -E \
                '^[[:xdigit:]]{64}[[:space:]]' \
                "$TMP_CHECKSUM" \
                | head -n 1 \
                | awk '{print $1}'
        )"
    fi

    if [[ -z "$expected" ]]; then
        echo
        echo "WARNING: Checksum file was found but the checksum"
        echo "for $OMARCHY_ISO_NAME could not be identified."
        return 0
    fi

    actual="$(
        sha256sum "$OMARCHY_ISO" \
        | awk '{print $1}'
    )"

    echo
    echo "Expected:"
    echo "  $expected"
    echo
    echo "Actual:"
    echo "  $actual"
    echo

    if [[ "${actual,,}" != "${expected,,}" ]]; then
        echo "ERROR: SHA-256 checksum verification FAILED."
        exit 1
    fi

    echo "SHA-256 verification PASSED."
}


download_signature() {
    echo
    echo "==> Checking for Omarchy ISO signature"

    if curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --output "$OMARCHY_SIG" \
        "$SIG_URL"; then

        echo "ISO signature downloaded:"
        ls -lh "$OMARCHY_SIG"

        echo
        echo "NOTE:"
        echo "The Omarchy signing key is:"
        echo "40DFB630FF42BCFFB047046CF0134EE680CAC571"
        echo
        echo "Cryptographic signature verification requires"
        echo "the Omarchy public key to be imported into GPG."
        echo "The SHA-256 verification above is performed automatically."
    else
        echo "No detached signature was available."
    fi
}


create_cidata() {
    echo
    echo "==> Creating unattended configuration"

    rm -rf "$CIDATA_DIR"
    mkdir -p "$CIDATA_DIR"

    # NOTE: Omarchy's manual documents the *purpose* of each cidata file
    # (disk/hostname/timezone/keyboard, username/password hash, etc.)
    # but not the literal on-disk key names. Before relying on this for
    # a real unattended install, run one interactive install in a
    # scratch VM and diff what its own wizard writes to /root against
    # the JSON generated below.
    cat > "$CIDATA_DIR/user_configuration.json" <<EOF
{
  "disk": "$INSTALL_DISK",
  "hostname": "$VM_NAME",
  "timezone": "$TIMEZONE",
  "keyboard": "$KEYBOARD"
}
EOF

    echo
    echo "Generating password"

    local password
    local password_hash

    read -r -s -p "Omarchy user password: " password < /dev/tty
    echo

    if [[ -z "$password" ]]; then
        echo "ERROR: No password entered."
        exit 1
    fi

    password_hash="$(openssl passwd -6 "$password")"

    unset password

    cat > "$CIDATA_DIR/user_credentials.json" <<EOF
{
  "username": "$USERNAME",
  "password": "$password_hash"
}
EOF

    unset password_hash

    if [[ -n "$FULL_NAME" ]]; then
        printf '%s\n' "$FULL_NAME" \
            > "$CIDATA_DIR/user_full_name.txt"
    fi

    if [[ -n "$GIT_EMAIL" ]]; then
        printf '%s\n' "$GIT_EMAIL" \
            > "$CIDATA_DIR/user_email_address.txt"
    fi

    if [[ "$ENABLE_SSH" == "true" ]]; then
        if [[ ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
            echo
            echo "SSH public key not found:"
            echo "  $SSH_PUBLIC_KEY_FILE"
            echo
            read -r -p "SSH public key path: " SSH_PUBLIC_KEY_FILE < /dev/tty
        fi

        if [[ ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
            echo "ERROR: SSH public key file does not exist."
            exit 1
        fi

        cp "$SSH_PUBLIC_KEY_FILE" \
            "$CIDATA_DIR/authorized_keys"
    fi

    if [[ "$ENABLE_TAILSCALE" == "true" ]]; then
        if [[ -z "$TAILSCALE_AUTHKEY" ]]; then
            read -r -s -p "Tailscale auth key: " TAILSCALE_AUTHKEY < /dev/tty
            echo
        fi

        if [[ -z "$TAILSCALE_AUTHKEY" ]]; then
            echo "ERROR: Tailscale was enabled but no auth key was supplied."
            exit 1
        fi

        printf '%s\n' "$TAILSCALE_AUTHKEY" \
            > "$CIDATA_DIR/tailscale_authkey"

        chmod 600 "$CIDATA_DIR/tailscale_authkey"
    fi

    chmod 600 "$CIDATA_DIR/user_credentials.json"

    echo
    echo "Generated:"
    find "$CIDATA_DIR" -maxdepth 1 -type f -printf '  %f\n'
}


create_cidata_iso() {
    echo
    echo "==> Creating $CIDATA_ISO_NAME"

    rm -f "$CIDATA_ISO"

    xorriso \
        -as mkisofs \
        -output "$CIDATA_ISO" \
        -volid cidata \
        -joliet \
        -rock \
        "$CIDATA_DIR"

    echo
    echo "Created:"
    ls -lh "$CIDATA_ISO"
}


copy_isos_to_proxmox_storage() {
    echo
    echo "==> Copying ISOs to Proxmox ISO storage"

    local iso_path
    local cidata_path

    # NOTE: the "2>/dev/null || true" must stay on the same line as the
    # command it applies to. Previously it sat on its own line, which
    # meant it silently attached to a no-op instead of the pvesm call
    # (harmless, but it let real pvesm errors print unsuppressed).
    iso_path="$(pvesm path "$ISO_STORAGE:iso/$OMARCHY_ISO_NAME" 2>/dev/null || true)"

    if [[ -z "$iso_path" ]]; then
        echo "Uploading Omarchy ISO to $ISO_STORAGE"

        pvesm upload \
            "$ISO_STORAGE" \
            "$OMARCHY_ISO" \
            --content iso

        iso_path="$(
            pvesm path "$ISO_STORAGE:iso/$OMARCHY_ISO_NAME"
        )"
    else
        echo "Omarchy ISO already exists in Proxmox storage."
    fi

    cidata_path="$(pvesm path "$ISO_STORAGE:iso/$CIDATA_ISO_NAME" 2>/dev/null || true)"

    if [[ -z "$cidata_path" ]]; then
        echo "Uploading $CIDATA_ISO_NAME to $ISO_STORAGE"

        pvesm upload \
            "$ISO_STORAGE" \
            "$CIDATA_ISO" \
            --content iso
    else
        echo "Removing previous $CIDATA_ISO_NAME"

        pvesm free \
            "$ISO_STORAGE:iso/$CIDATA_ISO_NAME"

        pvesm upload \
            "$ISO_STORAGE" \
            "$CIDATA_ISO" \
            --content iso
    fi
}


check_vmid() {
    echo
    echo "==> Checking VMID"

    if qm status "$VMID" >/dev/null 2>&1; then
        echo
        echo "ERROR: VMID $VMID already exists."
        qm config "$VMID"
        exit 1
    fi
}


create_vm() {
    echo
    echo "==> Creating Proxmox VM $VMID"

    qm create "$VMID" \
        --name "$VM_NAME" \
        --bios ovmf \
        --machine q35 \
        --cpu host \
        --cores "$CORES" \
        --memory "$MEMORY" \
        --ostype l26 \
        --scsihw virtio-scsi-single \
        --efidisk0 "$STORAGE:0,efitype=4m,pre-enrolled-keys=0" \
        --scsi0 "$STORAGE:$DISK_SIZE,discard=on,iothread=1" \
        --net0 "virtio,bridge=$BRIDGE" \
        --vga virtio \
        --serial0 socket \
        --ide2 "$ISO_STORAGE:iso/$OMARCHY_ISO_NAME,media=cdrom" \
        --ide3 "$ISO_STORAGE:iso/$CIDATA_ISO_NAME,media=cdrom" \
        --boot "order=scsi0;ide2" \
        --agent enabled=1

    echo
    echo "VM created:"
    qm config "$VMID"
}


start_vm() {
    echo
    echo "==> Starting VM $VMID"

    qm start "$VMID"

    echo
    echo "VM started."
}


wait_for_vm() {
    echo
    echo "==> Waiting for VM to start"

    local attempts=0

    while [[ "$attempts" -lt 30 ]]; do
        if qm status "$VMID" | grep -q "status: running"; then
            echo "VM is running."
            return 0
        fi

        sleep 2
        attempts=$((attempts + 1))
    done

    echo "WARNING: VM did not report running state."
}


print_connection_details() {
    echo
    echo "=========================================="
    echo " Omarchy VM created"
    echo "=========================================="
    echo
    echo "VMID:"
    echo "  $VMID"
    echo
    echo "Name:"
    echo "  $VM_NAME"
    echo
    echo "Username:"
    echo "  $USERNAME"
    echo
    echo "Proxmox console:"
    echo "  https://$(hostname -f):8006/"
    echo
    echo "SSH:"
    echo
    echo "  ssh $USERNAME@<VM-IP>"
    echo
    echo "Find the VM IP with:"
    echo
    echo "  qm guest cmd $VMID network-get-interfaces"
    echo
    echo "or:"
    echo
    echo "  ip neigh"
    echo
    if [[ "$ENABLE_TAILSCALE" == "true" ]]; then
        echo "Tailscale:"
        echo
        echo "  tailscale ip"
        echo
        echo "After the VM joins the tailnet:"
        echo
        echo "  ssh $USERNAME@<tailscale-ip>"
        echo
    fi
    echo "Omarchy ISO:"
    echo "  $OMARCHY_ISO"
    echo
    echo "cidata ISO:"
    echo "  $CIDATA_ISO"
    echo
    echo "The VM should install unattended and reboot"
    echo "from its virtual disk automatically."
    echo
    echo "=========================================="
    echo " IMPORTANT: cidata ISO contains secrets"
    echo "=========================================="
    echo
    echo "The cidata image carries your password hash"
    if [[ "$ENABLE_TAILSCALE" == "true" ]]; then
        echo "and your Tailscale auth key IN PLAINTEXT."
    fi
    echo "Once the unattended install has finished and"
    echo "the VM has rebooted into the desktop, remove"
    echo "it from Proxmox storage and detach the drive:"
    echo
    echo "  pvesm free \"$ISO_STORAGE:iso/$CIDATA_ISO_NAME\""
    echo "  qm set $VMID --delete ide3"
    echo
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

require_root
require_commands
require_tty
prompt_configuration
prepare_directories
check_vmid
download_iso
verify_iso_checksum
download_signature
create_cidata
create_cidata_iso
copy_isos_to_proxmox_storage
create_vm

echo
read -r -p "Start VM $VMID now? [Y/n] " START_VM < /dev/tty

if [[ ! "$START_VM" =~ ^[Nn]$ ]]; then
    start_vm
    wait_for_vm
fi

print_connection_details
