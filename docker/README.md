## Details

- 500 (docer)
- root/root
- root/root

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
## Install Ansible
```
docker pull ansible/ansible-runner:latest

docker run -it --rm \
  -v ~/ansible-playbooks:/playbooks \
  -v ~/.ssh:/root/.ssh \
  -v /etc/ansible:/etc/ansible \
  ansible/ansible-runner:latest bash

ansible --version
ansible-playbook /playbooks/site.yml -i /playbooks/inventory
```
## Install AWX

## Configure DockerHub Key and add to registry Personal access tokens https://docs.docker.com/security/access-tokens/




## Install Docker MCP on Linux https://github.com/docker/mcp-gateway
