# Setup Kali inside Docker

- https://github.com/onemarcfifty/kali-linux-docker/blob/main/build
- https://www.youtube.com/watch?v=JmF628xGk1A
- Kali Docker Image - https://www.kali.org/docs/containers/using-kali-docker-images/


```
docker run -d --name kali-rolling docker.io/kalilinux/kali-rolling tail -f /dev/null
docker exec -it kali-rolling /bin/bash

docker pull docker.io/kalilinux/kali-rolling
docker images -a
docker run -it -d --name kali kalilinux/kali-rolling /bin/bash

docker run --tty --interactive kalilinux/kali-rolling
docker container list --all
docker start d36922fa21e8
docker attach d36922fa21e8
```

```
DEBIAN_FRONTEND=noninteractive apt update && \
DEBIAN_FRONTEND=noninteractive apt install -y kali-linux-headless

DEBIAN_FRONTEND=noninteractive apt update && \
DEBIAN_FRONTEND=noninteractive apt install -y kali-linux-default xfce4 xfce4-goodies tightvncserver
```
ssh into it.
