# UniFi FTTP + DMZ + VLAN Architecture

```text
                                    Internet
                                       │
                              FTTP Ethernet (NBN)
                                       │
                         Optus NBN Router / NTD
                           (Bridge Mode Preferred)
                                       │
                                WAN Interface
                                       │
                     ┌───────────────────────────┐
                     │   UniFi Dream Machine Pro │
                     │         (UDM Pro)         │
                     │---------------------------│
                     │ Routing / Firewall / NAT  │
                     │ VLANs                     │
                     │ DHCP per VLAN             │
                     │ DNS per VLAN              │
                     │ IDS / IPS                 │
                     └─────────────┬─────────────┘
                                   │
                     ┌─────────────┴─────────────┐
                     │                           │
                     │ Trunk Port                │
                     │ VLAN 10,20,30             │
                     │                           │
         ┌───────────▼──────────┐     ┌──────────▼──────────┐
         │ UniFi Switch         │     │ UniFi Switch        │
         │ Home Network         │     │ DMZ Network         │
         │ (USW Pro 24 PoE)     │     │ (USW Pro 24)        │
         └───────────┬──────────┘     └──────────┬──────────┘
                     │                            │
      ┌──────────────┼──────────────┐             │
      │              │              │             │
      │              │              │             │
┌─────▼─────┐ ┌──────▼─────┐ ┌──────▼─────┐ ┌────▼─────┐
│ UniFi AP  │ │ Home PCs   │ │ NAS / Plex │ │ DMZ Host │
│ WiFi      │ │ TVs Phones │ │ Storage    │ │ Web App  │
└───────────┘ └────────────┘ └────────────┘ └──────────┘


────────────────────────────────────────────────────────────

VLAN CONFIGURATION

VLAN 10 - HOME
-----------------------------------
Subnet:      192.168.10.0/24
Gateway:     192.168.10.1
DHCP Server: 192.168.10.1
DNS Server:  192.168.10.1
Purpose:     Home devices

VLAN 20 - DMZ
-----------------------------------
Subnet:      192.168.20.0/24
Gateway:     192.168.20.1
DHCP Server: 192.168.20.1
DNS Server:  192.168.20.1
Purpose:     Public-facing services

VLAN 30 - MANAGEMENT (Optional)
-----------------------------------
Subnet:      192.168.30.0/24
Gateway:     192.168.30.1
DHCP Server: 192.168.30.1
DNS Server:  192.168.30.1
Purpose:     UniFi Controller / Admin


────────────────────────────────────────────────────────────

FIREWALL RULES

WAN  → DMZ     ALLOW
- TCP 80
- TCP 443
- TCP 22 (optional)

WAN  → HOME    DENY

HOME → DMZ     DENY
(or allow specific ports only)

DMZ  → HOME    DENY

HOME → WAN     ALLOW
DMZ  → WAN     ALLOW


────────────────────────────────────────────────────────────

PORT FORWARDING EXAMPLE

Public IP: x.x.x.x

TCP 80   → 192.168.20.10
TCP 443  → 192.168.20.10

Example:
Public HTTPS:
https://yourdomain.com

Internal DMZ Host:
192.168.20.10


────────────────────────────────────────────────────────────

RECOMMENDED UNIFI EQUIPMENT

- UniFi Dream Machine Pro (UDM Pro)
- UniFi Switch Pro 24 PoE
- UniFi Switch Lite / Flex (Optional)
- UniFi U6 Pro Access Points
- UniFi Protect (Optional)


────────────────────────────────────────────────────────────

NOTES

- Put Optus router into Bridge Mode if possible.
- If Bridge Mode is unavailable, use DMZ Passthrough to the UDM Pro WAN IP.
- Each VLAN has isolated DHCP/DNS services.
- Use Pi-hole or AdGuard Home if you want custom DNS filtering.
- Keep DMZ isolated from Home VLAN.
- Only expose required ports publicly.
- Consider Cloudflare Tunnel instead of direct port forwarding.
```
