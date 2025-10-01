- Install Docker 
- https://community-scripts.github.io/ProxmoxVE/scripts?id=docker-vm&category=Containers+%26+Docker
- Install Portainer

```
https://docs.portainer.io/start/install-ce/server/docker/linux 
curl -L https://downloads.portainer.io/ce-lts/portainer-compose.yaml docker compose -f portainer-compose.yaml up -d 
https://192.168.1.26:9443/#!/init/admin adminpassword123123
```
- Configure DockerHub Key and add to registry Personal access tokens https://docs.docker.com/security/access-tokens/
