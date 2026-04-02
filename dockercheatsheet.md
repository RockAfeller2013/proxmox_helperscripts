# Docker Cheat Sheet


## Clean up

```

docker rm -f dockurr/windows
docker volume prune -f
docker rmi dockurr/windows
docker system prune -a --volumes -f
ocker system df
docker image prune -a
docker system prune -a

```

## Docker Gracefull restart

```
docker ps -q | xargs -r docker stop && sleep 5 && systemctl stop docker && sleep 5 && shutdown now
```

## Docker Snapshots

```bash
docker commit <container_name_or_id> my-snapshot:v1
docker stop <container_name>
docker rm <container_name>
docker run --name <container_name> my-snapshot:v1
docker stop <container_name>
docker rm <container_name>
docker rmi my-snapshot:v1
```

## Docker Stack and Docker Compose

```
# Initialize swarm on single node
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml mystack

# View services
docker stack services mystack

# Remove stack
docker stack rm mystack

# Disable swarm mode
docker swarm leave --force

# Deploy stack
docker stack deploy -c docker-compose.yml mystack

# List stacks
docker stack ls

# List services in stack
docker stack services mystack

# Remove stack
docker stack rm mystack

```

## Expand Docker VM Storage
```
```bash
# 1. Check current disk and filesystem
lsblk
df -h

# 2. Install partition tools if missing
apt update && apt install -y cloud-guest-utils

# 3. Expand the partition to use full disk
growpart /dev/sda 3

# 4. Resize filesystem to fill partition
resize2fs /dev/sda3

# 5. Verify expansion
df -h
lsblk

# 6. Check Docker storage path and usage
docker info | grep "Docker Root Dir"
df -h /var/lib/docker
docker system df -v
  ````

## Docker Volumes clean up

```
# Docker Volumes

Persistent storage managed by Docker that exists outside the container lifecycle.  
Data persists even after the container is removed.  
Stored on the host and managed by Docker.  
Used to share data between containers.  
Preferred over bind mounts for portability.

# Commands

# Create a volume
docker volume create myvol

# Mount volume into a container
docker run -d -v myvol:/data nginx

# List all volumes
docker volume ls

# Inspect a volume's details
docker volume inspect myvol

# Remove a volume
docker volume rm myvol

# Remove Unused or Dangling Volumes

Volumes that are not attached to any container are considered dangling and can be safely removed to free space.

# Remove all dangling (unused) volumes
docker volume prune

# Remove all unused volumes (dangling and not referenced)
docker system prune -a --volumes

```

### Docker remove images
docker image prune -a
docker system prune -a
## Images
docker pull nginx
# Download image from registry

docker images
# List local images

docker rmi nginx
# Remove image

docker build -t myapp:latest .
# Build image from Dockerfile

## Containers
docker run -d -p 80:80 --name web nginx
# Run container in detached mode with port mapping

docker run -it ubuntu bash
# Run container interactively

docker ps
# List running containers

docker ps -a
# List all containers

docker stop web
# Stop container

docker start web
# Start container

docker restart web
# Restart container

docker rm web
# Remove container

## Logs & Exec
docker logs web
# View container logs

docker logs -f web
# Follow logs

docker exec -it web bash
# Access running container shell

## Networking
docker network ls
# List networks

docker network create mynet
# Create network

docker run -d --network mynet nginx
# Run container in network

## Volumes
docker volume ls
# List volumes

docker volume create myvol
# Create volume

docker run -d -v myvol:/data nginx
# Mount volume

docker volume rm myvol
# Remove volume

## System Cleanup
docker system df
# Show disk usage

docker system prune
# Remove unused data

docker container prune
# Remove stopped containers

docker image prune
# Remove unused images

docker volume prune
# Remove unused volumes

## Docker Compose
docker compose up -d
# Start services

docker compose down
# Stop and remove services

docker compose ps
# List services

docker compose logs -f
# Follow logs

docker compose build
# Build services

docker compose restart
# Restart services

## Inspect & Info
docker inspect web
# Detailed container info

docker stats
# Live resource usage

docker info
# System-wide info

docker version
# Show Docker version



