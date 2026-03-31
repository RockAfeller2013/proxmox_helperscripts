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

## Update script to block all outbound traffic except for Carbon Black Cloud

```python
#!/usr/bin/env python3
"""
Outbound firewall rules for Carbon Black Cloud (ProdSYD environment).

Blocks all outbound traffic from the host and Docker containers EXCEPT
traffic destined for Carbon Black Cloud endpoints.

Sources:
  - CBC ProdSYD firewall config:
    https://techdocs.broadcom.com/.../prodsyd-firewall-configuration.html
  - Cloudflare IP ranges (for updates2.cdc.carbonblack.io):
    https://www.cloudflare.com/ips/

Run as root. Idempotent — flushes and rebuilds the CBC-OUTPUT chain each time.
"""

import subprocess
import sys

# ---------------------------------------------------------------------------
# Carbon Black Cloud — ProdSYD fixed IP addresses
# Source: Broadcom TechDocs ProdSYD Firewall Configuration
# ---------------------------------------------------------------------------
CBC_IPS = [
    "34.117.142.85",    # dev-prodsyd.conferdeploy.net  — Sensor communications (primary TCP/443, backup TCP/54443)
    "34.160.100.116",   # content.carbonblack.io         — Sensor configuration / manifest updates
]

# ---------------------------------------------------------------------------
# Cloudflare IPv4 ranges
# Required for: updates2.cdc.carbonblack.io (signature updates)
# Source: https://www.cloudflare.com/ips-v4
# ---------------------------------------------------------------------------
CLOUDFLARE_IPS = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
]

# ---------------------------------------------------------------------------
# Additional CBC-related endpoints that use dynamic/cloud IPs.
# These require DNS-based resolution or broader cloud CIDR allow-listing.
# Documented here for reference — see notes below.
#
#   defense-prodsyd.conferdeploy.net  → Console/API access   (TCP/443)
#   dev-prodsyd.conferdeploy.net      → Sensor backend        (TCP/443 + 54443)
#   *.s3.amazonaws.com                → UBS / Exports (S3)   (TCP/443)
#   storage.googleapis.com            → Live Response / GCS  (TCP/443)
#   liveupdate.symantec.com           → Stargate LiveUpdate  (TCP/80, 443)
#   shasta-clt.symantec.com           → Stargate Telemetry   (TCP/443)
#   ent-shasta-rrs.symantec.com       → Stargate FileInsight (TCP/443)
#   ocsp.godaddy.com / ocsp.digicert.com  → OCSP             (TCP/80)
#   crl.godaddy.com / crl*.digicert.com   → CRL              (TCP/80)
#
# NOTE: S3 and GCS IPs are too large/dynamic to enumerate here.
# For a production environment, consider using a DNS-aware firewall
# (e.g. nftables with sets, or a proxy-based solution) for those hosts.
# ---------------------------------------------------------------------------

CHAIN_NAME = "CBC-OUTPUT"


def run(cmd: str, check: bool = True) -> None:
    """Run a shell command, printing it first for auditability."""
    print(f"  + {cmd}")
    subprocess.run(cmd, shell=True, check=check)


def chain_exists(chain: str) -> bool:
    result = subprocess.run(
        f"iptables -L {chain} -n",
        shell=True, capture_output=True
    )
    return result.returncode == 0


def setup_rules() -> None:
    print("\n[1/4] Setting up custom chain:", CHAIN_NAME)
    if chain_exists(CHAIN_NAME):
        # Flush existing rules so this script is idempotent
        run(f"iptables -F {CHAIN_NAME}")
    else:
        run(f"iptables -N {CHAIN_NAME}")

    # Hook into OUTPUT (host traffic) if not already present
    hook_check = subprocess.run(
        f"iptables -C OUTPUT -j {CHAIN_NAME}",
        shell=True, capture_output=True
    )
    if hook_check.returncode != 0:
        run(f"iptables -I OUTPUT -j {CHAIN_NAME}")

    # Hook into DOCKER-USER (container traffic) if not already present
    docker_check = subprocess.run(
        f"iptables -C DOCKER-USER -j {CHAIN_NAME}",
        shell=True, capture_output=True
    )
    if docker_check.returncode != 0:
        run(f"iptables -I DOCKER-USER -j {CHAIN_NAME}")

    print("\n[2/4] Allowing essential traffic")
    # Always allow loopback
    run(f"iptables -A {CHAIN_NAME} -o lo -j RETURN")
    # Allow already-established sessions (prevents breaking active connections)
    run(f"iptables -A {CHAIN_NAME} -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN")

    print("\n[3/4] Allowing Carbon Black Cloud fixed IPs (TCP/443 and TCP/54443)")
    for ip in CBC_IPS:
        run(f"iptables -A {CHAIN_NAME} -d {ip} -p tcp --dport 443  -j ACCEPT")
    # Sensor backup port — only needed for dev-prodsyd (sensor comms)
    run(f"iptables -A {CHAIN_NAME} -d 34.117.142.85 -p tcp --dport 54443 -j ACCEPT")

    print("\n[4/4] Allowing Cloudflare ranges (for updates2.cdc.carbonblack.io)")
    for cidr in CLOUDFLARE_IPS:
        run(f"iptables -A {CHAIN_NAME} -d {cidr} -p tcp --dport 443 -j ACCEPT")
        # Stargate LiveUpdate also uses TCP/80
        run(f"iptables -A {CHAIN_NAME} -d {cidr} -p tcp --dport 80  -j ACCEPT")

    # Drop everything else outbound — logged before dropping for diagnostics
    print("\n  Appending default DROP with logging")
    run(f'iptables -A {CHAIN_NAME} -m limit --limit 5/min -j LOG --log-prefix "CBC-FW-DROP: " --log-level 4')
    run(f"iptables -A {CHAIN_NAME} -j DROP")

    print("\n✓ Rules applied. Current CBC-OUTPUT chain:")
    run(f"iptables -L {CHAIN_NAME} -n -v")


def flush_rules() -> None:
    """Remove all CBC firewall rules (useful for rollback)."""
    print("Flushing", CHAIN_NAME, "rules...")
    if chain_exists(CHAIN_NAME):
        run(f"iptables -D OUTPUT     -j {CHAIN_NAME}", check=False)
        run(f"iptables -D DOCKER-USER -j {CHAIN_NAME}", check=False)
        run(f"iptables -F {CHAIN_NAME}", check=False)
        run(f"iptables -X {CHAIN_NAME}", check=False)
    print("✓ Rules flushed.")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "flush":
        flush_rules()
    else:
        setup_rules()
```

Two important caveats to be aware of:

-Dynamic cloud IPs — defense-prodsyd.conferdeploy.net (console), AWS S3 (UBS/Exports), and storage.googleapis.com (Live Response) all use large, frequently-rotating IP pools. iptables can't match by hostname, so for those you'd need a DNS-aware solution (e.g. nftables with dynamic sets, or a transparent proxy). They're documented in the script comments.
-Rollback — run sudo python3 cbc_firewall.py flush to remove all rules cleanly.


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
