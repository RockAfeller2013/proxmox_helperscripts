
## Install Caldera

- https://github.com/mitre/caldera.git


### Setup LXC GB+ RAM and 2+ CPUs

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"


```

### Enable Root SSH
```
sudo passwd root
# Set a password for root

sudo nano /etc/ssh/sshd_config
# Change or add the line:
PermitRootLogin yes

sudo systemctl restart ssh
```
### Full Upgrade
```
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo reboot
```




### Install Python 3.10+ (with Pip3) GoLang 1.24+ to dynamically compile GoLang-based agents NodeJS (v16+ recommended for v5 VueJS UI)

```
# Python 3.10+ with pip
sudo apt update && sudo apt install -y software-properties-common && sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt update && sudo apt install -y python3.10 python3.10-venv python3.10-distutils python3-pip

# GoLang 1.24+
wget https://go.dev/dl/go1.24.linux-amd64.tar.gz -O /tmp/go1.24.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go1.24.tar.gz && echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile && source ~/.profile

# NodeJS v16+
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && sudo apt install -y nodejs
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
```

### Docker Pull
```

docker run -p 7010:7010 -p 7011:7011 -p 7012:7012 -p 8888:8888 caldera:server

git clone https://github.com/mitre/caldera.git --recursive
cd caldera
docker build --build-arg VARIANT=full -t caldera .
docker run -p 7010:7010 -p 7011:7011 -p 7012:7012 -p 8888:8888 caldera:server

```
