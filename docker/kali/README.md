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

### Build Kali Container

```
docker ps
docker commit .. kali_mar_2026
docker images -a
docker run -d --name kali_run --it kali_mar_2026 /bin/bash

ocker run -d --name kali-rolling \ -p 5901:5901 \ docker.io/kalilinux/kali-rolling \ /bin/bash -c "export USER=root && \ mkdir -p /root/.vnc && \ echo 'yourpassword' | vncpasswd -f > /root/.vnc/passwd && \ chmod 600 /root/.vnc/passwd && \ tightvncserver :1 -geometry 1920x1080 -depth 24 && \ startxfce4 && tail -f /dev/null"

```

VNC into it

```
docker run -d --name kali-rolling -p 5901:5901 docker.io/kalilinux/kali-rolling tail -f /dev/null

docker run -d --name kali-rolling -p 5901:5901 docker.io/kalilinux/kali-rolling \
/bin/bash -c "tightvncserver :1 && tail -f /dev/null"

docker stop kali-rolling
docker rm kali-rolling

docker run -d --name kali-rolling \
  -p 5901:5901 \
  docker.io/kalilinux/kali-rolling \
  /bin/bash -c "tightvncserver :1 && tail -f /dev/null"

docker run -d --name kali-rolling \
  -p 5901:5901 \
  docker.io/kalilinux/kali-rolling \
  /bin/bash -c "export USER=root && \
                mkdir -p /root/.vnc && \
                echo 'yourpassword' | vncpasswd -f > /root/.vnc/passwd && \
                chmod 600 /root/.vnc/passwd && \
                tightvncserver :1 -geometry 1920x1080 -depth 24 && \
                startxfce4 && tail -f /dev/null"
```
