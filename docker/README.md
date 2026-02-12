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
On MacOSX and Chrome, CONTROl + SHIFT + R to refresh
