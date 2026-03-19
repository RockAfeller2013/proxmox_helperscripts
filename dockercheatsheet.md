# Docker Cheat Sheet

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
