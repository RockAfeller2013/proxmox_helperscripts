# Guacamole Auto VNC Connection Script

- https://chatgpt.com/c/69bcfdd0-c818-8322-a681-18e3402aa15e

## Overview

This solution automatically discovers Docker containers with exposed VNC ports and creates corresponding connections in Guacamole using its REST API.

---

## How It Works

- Lists running Docker containers
- Inspects each container for exposed VNC ports (`5900`)
- Extracts mapped host port
- Creates a VNC connection in Guacamole
- Skips containers without VNC

---

## Requirements

- Docker installed
- Guacamole running and accessible
- Python 3.10+
- Python module:

```bash

pip install requests
