#!/usr/bin/env bash
# =============================================================================
# Kali Linux Docker Setup Script
# Pulls kali-rolling, installs kali-linux-headless, and makes it persistent
# bash <(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/main/docker/kali/kalidockerbuild.sh)
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
CONTAINER_NAME="kali-rolling"
BASE_IMAGE="docker.io/kalilinux/kali-rolling"
CUSTOM_IMAGE="kali-rolling-custom"
VOLUME_NAME="kali-data"
DOCKER_NETWORK="my-net2"
SSH_HOST_PORT="2222"
SSH_ROOT_PASSWORD="kali"        # ← Change this before running!

# --- Colours -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# --- Preflight checks --------------------------------------------------------
check_docker() {
  info "Checking Docker is available..."
  if ! command -v docker &>/dev/null; then
    error "Docker is not installed or not in PATH. Install Docker first."
  fi
  if ! docker info &>/dev/null; then
    error "Docker daemon is not running. Start it with: sudo systemctl start docker"
  fi
  success "Docker is available."
}

# --- Ensure network exists ---------------------------------------------------
ensure_network() {
  info "Checking Docker network '${DOCKER_NETWORK}'..."
  if ! docker network inspect "${DOCKER_NETWORK}" &>/dev/null; then
    warn "Network '${DOCKER_NETWORK}' not found. Creating it..."
    docker network create "${DOCKER_NETWORK}"
    success "Network '${DOCKER_NETWORK}' created."
  else
    success "Network '${DOCKER_NETWORK}' already exists."
  fi
}

# --- Cleanup any existing container ------------------------------------------
cleanup_existing() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "Container '${CONTAINER_NAME}' already exists. Removing it..."
    docker rm -f "${CONTAINER_NAME}"
    success "Existing container removed."
  fi
}

# --- Pull image --------------------------------------------------------------
pull_image() {
  info "Pulling ${BASE_IMAGE}..."
  docker pull "${BASE_IMAGE}"
  success "Image pulled."
}

# --- Start temporary container -----------------------------------------------
start_temp_container() {
  info "Starting temporary container '${CONTAINER_NAME}'..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    "${BASE_IMAGE}" \
    tail -f /dev/null
  success "Temporary container started."
}

# --- Install kali-linux-headless + SSH ---------------------------------------
install_packages() {
  info "Installing kali-linux-headless + openssh-server (this may take 5-15 minutes)..."
  docker exec "${CONTAINER_NAME}" bash -c "
    DEBIAN_FRONTEND=noninteractive apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y kali-linux-headless openssh-server && \
    mkdir -p /var/run/sshd && \
    echo 'root:${SSH_ROOT_PASSWORD}' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'service ssh start' >> /root/.bashrc
  "
  success "Packages installed and SSH configured."
}

# --- Commit to a new image ---------------------------------------------------
commit_image() {
  info "Committing container to image '${CUSTOM_IMAGE}'..."
  if docker image inspect "${CUSTOM_IMAGE}" &>/dev/null; then
    warn "Image '${CUSTOM_IMAGE}' already exists. Replacing it..."
    docker rmi -f "${CUSTOM_IMAGE}"
  fi
  docker commit "${CONTAINER_NAME}" "${CUSTOM_IMAGE}"
  success "Image committed as '${CUSTOM_IMAGE}'."
}

# --- Remove temp container and start the real persistent one -----------------
start_persistent_container() {
  info "Removing temporary container..."
  docker rm -f "${CONTAINER_NAME}"

  info "Creating persistent Docker volume '${VOLUME_NAME}'..."
  docker volume create "${VOLUME_NAME}" &>/dev/null
  success "Volume '${VOLUME_NAME}' ready."

  info "Starting persistent container on network '${DOCKER_NETWORK}' with SSH on port ${SSH_HOST_PORT}..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --network "${DOCKER_NETWORK}" \
    -p "${SSH_HOST_PORT}:22" \
    -v "${VOLUME_NAME}:/root" \
    "${CUSTOM_IMAGE}" \
    bash -c "/usr/sbin/sshd && tail -f /dev/null"
  success "Persistent container '${CONTAINER_NAME}' is running."
}

# --- Verify ------------------------------------------------------------------
verify() {
  info "Verifying setup..."
  RESTART_POLICY=$(docker inspect "${CONTAINER_NAME}" --format '{{.HostConfig.RestartPolicy.Name}}')
  STATUS=$(docker inspect "${CONTAINER_NAME}" --format '{{.State.Status}}')
  NETWORK=$(docker inspect "${CONTAINER_NAME}" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
  IP=$(docker inspect "${CONTAINER_NAME}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['NetworkSettings']['Networks'].get('${DOCKER_NETWORK}',{}).get('IPAddress','N/A'))")
  echo ""
  echo -e "  Container name   : ${CYAN}${CONTAINER_NAME}${NC}"
  echo -e "  Status           : ${GREEN}${STATUS}${NC}"
  echo -e "  Restart policy   : ${GREEN}${RESTART_POLICY}${NC}"
  echo -e "  Network          : ${GREEN}${NETWORK}${NC}"
  echo -e "  IP on ${DOCKER_NETWORK}   : ${GREEN}${IP}${NC}"
  echo -e "  SSH port (host)  : ${GREEN}${SSH_HOST_PORT}${NC}"
  echo -e "  SSH root password: ${YELLOW}${SSH_ROOT_PASSWORD}${NC}  <- Change this!"
  echo -e "  Persistent volume: ${CYAN}${VOLUME_NAME}${NC} -> /root"
  echo -e "  Saved image      : ${CYAN}${CUSTOM_IMAGE}${NC}"
  echo ""
  success "Setup complete!"
}

# --- Usage hint --------------------------------------------------------------
print_usage() {
  echo ""
  echo -e "${CYAN}Useful commands:${NC}"
  echo "  SSH into Kali       : ssh root@<host-vm-ip> -p ${SSH_HOST_PORT}"
  echo "  Shell into Kali     : docker exec -it ${CONTAINER_NAME} bash"
  echo "  Stop container      : docker stop ${CONTAINER_NAME}"
  echo "  Start container     : docker start ${CONTAINER_NAME}"
  echo "  Remove container    : docker rm -f ${CONTAINER_NAME}"
  echo "  Inspect network     : docker network inspect ${DOCKER_NETWORK}"
  echo "  Change SSH password : docker exec -it ${CONTAINER_NAME} passwd root"
  echo "  Rebuild from image  : docker run -d --name ${CONTAINER_NAME} --restart unless-stopped --network ${DOCKER_NETWORK} -p ${SSH_HOST_PORT}:22 -v ${VOLUME_NAME}:/root ${CUSTOM_IMAGE} bash -c '/usr/sbin/sshd && tail -f /dev/null'"
  echo ""
  echo -e "${YELLOW}Security reminder: Change the root SSH password after first login!${NC}"
  echo "  docker exec -it ${CONTAINER_NAME} passwd root"
  echo ""
}

# --- Main --------------------------------------------------------------------
main() {
  echo ""
  echo -e "${CYAN}============================================${NC}"
  echo -e "${CYAN}   Kali Linux Docker Setup                 ${NC}"
  echo -e "${CYAN}============================================${NC}"
  echo ""

  check_docker
  ensure_network
  cleanup_existing
  pull_image
  start_temp_container
  install_packages
  commit_image
  start_persistent_container
  verify
  print_usage
}

main "$@"
