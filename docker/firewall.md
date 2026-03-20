# Restrict Docker Container Access to Internal Network

## Overview

Docker containers can access external networks by default. This setup restricts container access to your internal network (`192.168.0.0/16`) while allowing specific IPs (for example, `192.168.1.146`).

This is implemented using `iptables` and the `DOCKER-USER` chain, which Docker evaluates before its own rules.

---

## How It Works

Rules are applied in this order:

1. **Allow established connections**

   * Ensures return traffic for valid connections is not blocked.

2. **Allow specific IPs**

   * Explicitly permits traffic to approved internal IPs.

3. **Deny all other internal traffic**

   * Blocks access to the rest of the internal network.

---

## Python Script

```python
#!/usr/bin/env python3

import subprocess

# Docker bridge interface (default)
DOCKER_BRIDGE = "docker0"

# Allowed internal IPs
ALLOWED_IPS = ["192.168.1.146"]


def run(cmd):
    subprocess.run(cmd, shell=True, check=True)


def setup_rules():
    # Allow established/related traffic
    run("iptables -I DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT")

    # Allow specific internal IPs
    for ip in ALLOWED_IPS:
        run(f"iptables -I DOCKER-USER -d {ip} -j ACCEPT")

    # Drop all other traffic to internal network
    run("iptables -I DOCKER-USER -d 192.168.0.0/16 -j DROP")


if __name__ == "__main__":
    setup_rules()
```

---

## Usage

1. Save the script:

   ```bash
   nano restrict_docker_internal.py
   ```

2. Make it executable:

   ```bash
   chmod +x restrict_docker_internal.py
   ```

3. Run as root:

   ```bash
   sudo ./restrict_docker_internal.py
   ```

---

## Notes

* Rules apply to **all containers** on the host.

* The `DOCKER-USER` chain persists across container restarts but **not system reboots** unless saved.

* To persist rules:

  ```bash
  sudo iptables-save > /etc/iptables/rules.v4
  ```

* To allow more IPs, update:

  ```python
  ALLOWED_IPS = ["192.168.1.146", "192.168.1.200"]
  ```

---

## Result

* Containers **can access the internet**
* Containers **can access only allowed internal IPs**
* Containers **cannot access the rest of your internal network**
