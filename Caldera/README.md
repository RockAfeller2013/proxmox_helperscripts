
## Install Caldera

- https://github.com/mitre/caldera.git


### Setup LXC GB+ RAM and 2+ CPUs

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"


```

### Enable Root SSH

```
dpkg --configure -a
apt update && apt install -y openssh-server && mkdir -p /var/run/sshd && sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && /usr/sbin/sshd -D &
sudo passwd root


sudo passwd root
sudo sed -i '/^PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
```
### Full Upgrade
```
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo reboot
```

### Install Python 3.10+ (with Pip3) GoLang 1.24+ to dynamically compile GoLang-based agents NodeJS (v16+ recommended for v5 VueJS UI)

```
sudo apt install python3-pip -y
sudo apt install git -y
sudo apt install python3.13-venv -y

```

### NodeJS
```
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## GoLang

```
sudo apt-get update
sudo apt-get install -y wget tar

wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile

go version

```
```
python3 -m venv .calderavenv
source .calderavenv/bin/activate
```

```
git clone https://github.com/mitre/caldera.git --recursive
cd caldera
pip3 install -r requirements.txt
python3 server.py --insecure --build
```

```
git submodule add https://github.com/mitre/magma
cd plugins/magma && npm install && cd ..
python3 server.py --uidev localhost
pm install -g npm@11.10.0
```

### Docker Pull
```

docker run -p 7010:7010 -p 7011:7011 -p 7012:7012 -p 8888:8888 caldera:server

git clone https://github.com/mitre/caldera.git --recursive
cd caldera
docker build --build-arg VARIANT=full -t caldera .
docker run -p 7010:7010 -p 7011:7011 -p 7012:7012 -p 8888:8888 caldera:server

```
