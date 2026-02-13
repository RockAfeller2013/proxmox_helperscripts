
## Install Caldera

- https://github.com/mitre/caldera.git


### Setup LXC 
GB+ RAM and 2+ CPUs

### Install Python 3.10+ (with Pip3)
GoLang 1.24+ to dynamically compile GoLang-based agents
NodeJS (v16+ recommended for v5 VueJS UI)

```
python3 -m venv .calderavenv
source .calderavenv/bin/activate
```

```
python3 -m venv .calderavenv
source .calderavenv/bin/activate
```


```
git submodule add https://github.com/mitre/magma
cd plugins/magma && npm install && cd ..
python3 server.py --uidev localhost
```

```

docker run -p 7010:7010 -p 7011:7011 -p 7012:7012 -p 8888:8888 caldera:server

git clone https://github.com/mitre/caldera.git --recursive
cd caldera
docker build --build-arg VARIANT=full -t caldera .
docker run -p 7010:7010 -p 7011:7011 -p 7012:7012 -p 8888:8888 caldera:server



```
