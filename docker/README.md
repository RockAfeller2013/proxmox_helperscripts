## Details

- 500 (docer)
- root/root
- root/root
- https://chatgpt.com/c/6982deef-bdc0-8323-90c1-13c23494efe1
- https://claude.ai/chat/7da8ac7c-c82e-4214-b303-46dfc0f6cca9

## Setup Docker VM 

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/docker-vm.sh)"
```
## Enable root SSH
```
ssh-keygen -R 192.168.1.37

username: root
Password: root

dpkg --configure -a
apt update && apt install -y openssh-server && mkdir -p /var/run/sshd && sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && /usr/sbin/sshd -D &
sudo passwd root
```

## Setup Protainer inside Docker VM
```
docker volume create portainer_data

docker run -d \
  --name portainer \
  --restart=always \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

https://192.168.1.37:9443/#!/init/admin
```
- https://docs.portainer.io/start/install-ce/server/docker/linux 
- curl -L https://downloads.portainer.io/ce-lts/portainer-compose.yaml docker compose -f portainer-compose.yaml up -d 

- https://192.168.1.37:9443/#!/init/admin admin/Wi{S0REjCE6%

## Install Docker Compose plugin
```
docker compose version || apt install -y docker-compose-plugin
```
## Install Ansible as a Docker image

1. Promox VM with Ansible to provision Docker and other VMs inside Promox
2. Ansible Docker Container inside Docker , just to test provisioning inside a single VM/Docker Host

| Aspect | Your Version | My Version |
|--------|--------------|------------|
| **Manages** | Remote Linux servers | Local Docker containers |
| **Connects via** | SSH | Docker socket |
| **Mounts** | SSH keys | Docker socket |
| **Use case** | Configure VMs/bare metal | Orchestrate containers |
| **Target** | `hosts: webservers` | `hosts: localhost` |


- https://docs.ansible.com/projects/ansible/latest/collections/community/docker/docsite/scenario_guide.html
- https://hub.docker.com/r/ansible/ansible
- You can change the connection type of Ansible from SSH to Docker using ansible_connection: docker in your inventory file or --connection docker from the command line. This will allow you to use Docker hostnames as inventory. The documentation can be found here: https://docs.ansible.com/ansible/latest/plugins/connection.htm
- https://akshaybobade777.medium.com/setup-ansible-on-docker-containers-75b0707726bd
- https://www.youtube.com/watch?v=rZAVKybbL40
  
```
mkdir -p /opt/ansible-runner/{inventory,playbooks,roles,env}

docker pull quay.io/ansible/ansible-runner:latest

docker run -d \
  --name ansible-runner \
  --restart unless-stopped \
  -v /opt/ansible-runner:/runner \
  -v ~/.ssh:/root/.ssh:ro \
  -w /runner \
  quay.io/ansible/ansible-runner:latest \
  sleep infinity

docker exec -it ansible-runner ansible --version
docker exec -it ansible-runner ansible-runner --version
docker exec -it ansible-runner ansible-playbook -i inventory/hosts playbooks/site.yml
docker exec -it ansible-runner bash

```

## Ansible tet file

```
mkdir -p /opt/ansible-runner/playbooks

cat <<'EOF' > /opt/ansible-runner/playbooks/site.yml
---
- name: Test playbook
  hosts: all
  gather_facts: false
  tasks:
    - name: Ping hosts
      ping:
EOF


cat <<'EOF' > /opt/ansible-runner/inventory/hosts
[all]
127.0.0.1 ansible_connection=local
EOF


```

## Semaphore UI

Semaphore will use the mounted /opt/ansible directory (same one used by ansible-runner) to manage playbooks and inventory.

```

docker rm -f semaphore

docker pull semaphoreui/semaphore:latest

mkdir -p /opt/semaphore/{data,config}
mkdir -p /opt/semaphore
chown -R 1001:1001 /opt/semaphore

docker run -d \
  --name semaphore \
  --restart unless-stopped \
  -p 3000:3000 \
  -e SEMAPHORE_DB_DIALECT=sqlite \
  -e SEMAPHORE_DB_HOST=/etc/semaphore/semaphore.db \
  -e SEMAPHORE_ADMIN=admin \
  -e SEMAPHORE_ADMIN_PASSWORD=admin \
  -e SEMAPHORE_ADMIN_NAME=admin \
  -e SEMAPHORE_ADMIN_EMAIL=admin@example.com \
  -v /opt/semaphore:/etc/semaphore \
  -v /opt/ansible-runner:/opt/ansible \
  -v ~/.ssh:/home/semaphore/.ssh:ro \
  semaphoreui/semaphore:latest

docker ps | grep semaphore
docker logs semaphore


http://192.168.1.37:3000 admin/admiin

```
## Install AWX

## Configure DockerHub Key and add to registry Personal access tokens https://docs.docker.com/security/access-tokens/

- You are currently using an anonymous account to pull images from DockerHub and will be limited to 100 pulls every 6 hours. You can configure DockerHub authentication in the Registries View. Remaining pulls: 100/100


## Install Docker MCP on Linux https://github.com/docker/mcp-gateway

## Commands

```
USING WEB-BASED LOGIN

i Info → To sign in with credentials on the command line, use 'docker login -u <username>'


Your one-time device confirmation code is: SQVR-CRSD
Press ENTER to open your browser or submit your device code here: https://login.docker.com/activate

Waiting for authentication in the browser…

WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

login with gmail.
```

### Ansible Playbook: install-docker.yml


```
---
- name: Install Docker on Ubuntu using official Docker repo
  hosts: all
  become: true

  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes

    - name: Ensure dependencies are installed
      ansible.builtin.package:
        name:
          - bc
          - curl
          - expect
          - git
          - ca-certificates
        state: present

    - name: Create Docker GPG key directory
      ansible.builtin.file:
        path: /etc/apt/keyrings
        state: directory
        mode: "0755"

    - name: Download Docker's official GPG key
      ansible.builtin.get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: /etc/apt/keyrings/docker.asc
        mode: "0644"

    - name: Add Docker repository to Apt sources
      ansible.builtin.apt_repository:
        repo: "deb [arch={{ ansible_architecture }} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
        filename: docker

    - name: Update apt cache after adding Docker repository
      ansible.builtin.apt:
        update_cache: yes

    - name: Install Docker and Docker Compose
      ansible.builtin.package:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
        state: present

    - name: Ensure Docker service is enabled and started
      ansible.builtin.service:
        name: docker
        state: started
        enabled: yes

    - name: Add ubuntu user to docker group
      ansible.builtin.user:
        name: ubuntu
        groups: docker
        append: yes
```

## References

- https://github.com/dark-matter08/dev-ops-tool-on-docker


## Comparision

| **Image**                        | **Usable Ansible CLI** | **Maintained**  | **Upstream / Official** | **Base OS**      | **Primary Use Case**        | **Includes ansible-runner** | **Includes Python** | **Collections Pre-Installed** | **Extra Tools (git/ssh/docker)** | **Best Fit**            |
| -------------------------------- | ---------------------- | --------------- | ----------------------- | ---------------- | --------------------------- | --------------------------- | ------------------- | ----------------------------- | -------------------------------- | ----------------------- |
| `ansible/ansible`                | ❌ No                   | ❌ No            | ❌ No                    | Ubuntu (legacy)  | Internal testing only       | ❌                           | ⚠️ Partial          | ❌                             | ❌                                | Do not use              |
| `quay.io/ansible/ansible-runner` | ✅ Yes                  | ✅ Yes           | ✅ **Official**          | UBI / RHEL-based | Execution environments      | ✅                           | ✅                   | ❌ (minimal)                   | ⚠️ Minimal                       | Runner-based automation |
| `quay.io/ansible/awx-ee`         | ✅ Yes                  | ✅ Yes           | ✅ **Official**          | UBI / RHEL-based | AWX / Automation Controller | ✅                           | ✅                   | ✅                             | ✅ (git, ssh)                     | AWX / Enterprise-style  |
| `oowy/ansible`                   | ✅ Yes                  | ✅ Yes           | ❌ Community             | Alpine Linux     | Lightweight CLI usage       | ❌                           | ✅                   | ❌                             | ⚠️ Minimal                       | Homelab / scripts       |
| `gwerlas/ansible`                | ✅ Yes                  | ✅ Yes           | ❌ Community             | Debian/Ubuntu    | Infra automation            | ❌                           | ✅                   | ⚠️ Some                       | ✅ (docker, kubectl, cloud CLIs)  | Ops / multi-tool        |
| `williamyeh/ansible`             | ✅ Yes                  | ⚠️ Low activity | ❌ Community             | Debian/Ubuntu    | Simple playbook runs        | ❌                           | ✅                   | ❌                             | ⚠️ Minimal                       | Legacy / simple tasks   |



# Symantec Health Check Docker

//Volumes/web/files

```
docker rm -f symhealth_app

curl -L -k -o symhealth_app.tar https://192.168.1.146/files/symhealth_app.tar && \
docker load -i symhealth_app.tar && \
docker run -d --name symhealth_app -p 8080:8081 symhealth_app

```

```
docker exec -it symhealth_app sh -c "ss -tulnp || netstat -tulnp"
docker ps | grep semaphore
docker logs semaphore
```
Manual Docker Start
```
docker update --restart=no symhealth_app
docker inspect -f '{{ .HostConfig.RestartPolicy.Name }}' symhealth_app
docker start symhealth_app
docker stop symhealth_app


```

Edit the background , inside the container console, Insert the following at the end of /symhealth/media/style.css and restart

```

yum install -y nano
nano /symhealth/media/style.css

html,
body {
    background-color: #000000 !important;
    background-image: none !important;
}

```
Download the App Control Script to server and run it

```
PowerShell -ExecutionPolicy Bypass -File "C:\Users\Administrator\Downloads\App_Control_On-Prem_Script\ac_ta.ps1"

```
On MacOSX and Chrome, COMMAND + SHIFT + R to refresh

Create Carbon Black App Control API User and Generate API
- API Authentication and Access Control - https://techdocs.broadcom.com/us/en/carbon-black/app-control/carbon-black-app-control/8-11-2/app-control-user-guide_tile/GUID-757E4F0C-1A20-4B38-B7D6-B8063C71C02C-en/GUID-47338240-780C-4B97-9921-285EEEF06F4C-en.html
- Create an API User and Get its API Token - https://techdocs.broadcom.com/us/en/carbon-black/app-control/carbon-black-app-control/8-11-2/app-control-user-guide_tile/GUID-757E4F0C-1A20-4B38-B7D6-B8063C71C02C-en/GUID-47338240-780C-4B97-9921-285EEEF06F4C-en/GUID-6529F642-7C7D-4AFE-90DD-EB3448F98106-en.html
- Carbon Black App Control API - https://techdocs.broadcom.com/us/en/carbon-black/app-control/carbon-black-app-control/8-11-2/app-control-user-guide_tile/GUID-757E4F0C-1A20-4B38-B7D6-B8063C71C02C-en.html
- Getting Started with App Control APIs & Integrations - https://developer.carbonblack.com/reference/enterprise-protection/
- App Control REST API Reference - https://developer.carbonblack.com/reference/enterprise-protection/7.2/rest-api/
- Manage API Users and Tokens - https://knowledge.broadcom.com/external/article/286247/manage-api-users-and-tokens.html
- Use Postman to Retrieve Data Via API - https://knowledge.broadcom.com/external/article?articleNumber=286470




```
curl -k -H "X-Auth-Token: 5702D0DE-4EB6-4A1D-BD63-4374B12A0816" "https://192.168.1.26/api/bit9platform/v1/event"
curl -k -H "X-Auth-Token: 5702D0DE-4EB6-4A1D-BD63-4374B12A0816" "https://192.168.1.26/api/bit9platform/v1/info"
curl -k -H "X-Auth-Token: 5702D0DE-4EB6-4A1D-BD63-4374B12A0816" "https://192.168.1.26/api/bit9platform/v1/Computer?group=osShortName?"
curl -k -H "X-Auth-Token: 5702D0DE-4EB6-4A1D-BD63-4374B12A0816" "https://192.168.1.26/api/bit9platform/restricted/agentConfig?limit=-1"

```

## Memo

- https://github.com/usememos/memos


# Windows on Docker 

- https://github.com/dockur/windows

### Windows 11
```

sudo apt install cpu-checker
sudo kvm-ok

docker run --rm -v "${PWD:-.}/windows:/storage" busybox df -h /storage


docker run -it --rm --name windows -e "VERSION=11" -p 8006:8006 --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN -v "${PWD:-.}/windows:/storage" --stop-timeout 120 docker.io/dockurr/windows

docker run -d --name windows \
  -e "VERSION=11" \
  -p 8006:8006 \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$(df --output=target,size,avail | awk 'NR>1 {print $3,$1}' | sort -nr | head -n1 | awk '{print $2"/windows"}'):/storage" \
  --stop-timeout 120 \
  docker.io/dockurr/windows


```

```
docker rm -f dockurr/windows
docker volume prune -f
docker rmi dockurr/windows
docker system prune -a --volumes -f
```
### Use RDP Instead, as VNC doesn't support clipboard
```
docker run -d \
  --name windows \
  -e VERSION=11 \
  -p 8006:8006 \
  -p 5900:5900 \
  -p 3389:3389 \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  dockurr/windows
```

### Windows XP

```
docker run -d --name windows-xp \
  -e "VERSION=xp" \
  -p 8007:8006 \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$(df --output=target,size,avail | awk 'NR>1 {print $3,$1}' | sort -nr | head -n1 | awk '{print $2"/windows-xp"}'):/storage" \
  -v "/path/to/your/oem:/oem" \
  --stop-timeout 120 \
  docker.io/dockurr/windows

docker logs -f --tail 50 windows-xp

ocker network inspect guacamole-docker-compose_guacnetwork_compose -f '{{range .Containers}}{{.Name}} {{end}}'
docker network connect guacamole-docker-compose_guacnetwork_compose windows-xp

## Gucamole Connections that works

Protocol: VNC / Hostname: windows-xp / Port:5900


```
### Here’s how to make install.bat run automatically on first boot of your dockur/windows VM based on the repository docs:


```
1. Create your install folder

On your host, create a folder (e.g., oem) that contains your install.bat and any files it needs (installers, scripts, etc.).

2. Put your script inside

Your directory structure should look like:

oem/
├── install.bat
├── program1.exe
├── other-files …
3. Bind the folder into the container

Update your docker run command to mount that folder to /oem inside the container.

Example updated command:

docker run -d --name windows-xp \
  -e "VERSION=xp" \
  -p 8007:8006 \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$(df --output=target,size,avail | awk 'NR>1 {print $3,$1}' | sort -nr | head -n1 | awk '{print $2"/windows-xp"}'):/storage" \
  -v "/path/to/your/oem:/oem" \
  --stop-timeout 120 \
  docker.io/dockurr/windows

Replace /path/to/your/oem with the real path where your install.bat folder lives.

4. What happens on first boot

During the automated installation process:

The container copies your host folder into C:\OEM in the Windows VM.

At the last step of the installation, the VM executes install.bat automatically.

No extra environment flags are needed — just the volume mount.

```

## Guacamole

- https://github.com/boschkundendienst/guacamole-docker-compose

```


git clone "https://github.com/boschkundendienst/guacamole-docker-compose.git"
cd guacamole-docker-compose
./prepare.sh
docker compose up -d

https://192.168.1.37:8443/#/ guacadmin/guacadmin
To reset everything to the beginning, just run ./reset.sh.

docker network ls
docker network inspect <network-name>

# create network
docker network create guac-net

docker network connect guac-net <existing-container>

```

### Setup MySQL (Manual, above works.) 

```
# Run MySQL container (detached)
docker run -d \
  --name mysql-server \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=initial_db \
  -p 3306:3306 \
  mysql:8.0
# Execute SQL commands inside the container
docker exec -i mysql-server mysql -uroot -prootpass <<EOF
CREATE DATABASE my_app_db;
USE my_app_db;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username) VALUES ('admin');
EOF

# Verify
docker exec -it mysql-server mysql -uroot -prootpass -e "SHOW DATABASES;"
```
# Enable Docker Compose

```
# Check if Docker Compose (v2 plugin) is already installed
docker compose version

# --- If NOT installed, install Docker Compose plugin (Linux) ---

# Update package index
sudo apt-get update

# Install Docker Compose plugin
sudo apt-get install -y docker-compose-plugin

# Verify installation
docker compose version

# --- Optional: Enable docker command without sudo ---
sudo usermod -aG docker $USER
newgrp docker

# --- Test with a sample compose file ---
cat <<EOF > docker-compose.yml
services:
  hello:
    image: hello-world
EOF

docker compose up

# --- Clean up ---
docker compose down
rm docker-compose.yml
```
