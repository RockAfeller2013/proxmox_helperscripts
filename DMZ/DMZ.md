# UniFi Dream Machine — Network Architecture

```mermaid
architecture-beta
    service inet(internet)[Internet]
    service nbn(server)[NBN Router]
    service udm(server)[Dream Machine]

    group v10(cloud)[VLAN 10 - Home Network]
        service ap(server)[WiFi APs] in v10
        service homedev(server)[Home Devices] in v10
        service nas(disk)[Home NAS] in v10

    group v20(cloud)[VLAN 20 - DMZ]
        service dms(server)[DMS Server] in v20
        service webmail(server)[Web and Mail] in v20

    group v30(cloud)[VLAN 30 - Management]
        service ctrl(server)[UniFi Controller] in v30
        service adminpc(server)[Admin PC] in v30

    inet:B -- T:nbn
    nbn:B -- T:udm
    udm:L -- R:ap
    udm:B -- T:dms
    udm:R -- L:ctrl
```

## Subnets

| VLAN | Name       | Subnet           | Gateway      |
|------|------------|------------------|--------------|
| 10   | Home       | 192.168.10.0/24  | 192.168.10.1 |
| 20   | DMZ        | 192.168.20.0/24  | 192.168.20.1 |
| 30   | Management | 192.168.30.0/24  | 192.168.30.1 |

## Firewall Rules

| Direction  | Action | Source  | Destination | Notes                     |
|------------|--------|---------|-------------|---------------------------|
| WAN → DMZ  | Allow  | Any     | VLAN 20     | Ports 80, 443, 22 only    |
| WAN → Home | Deny   | Any     | VLAN 10     | Block all                 |
| DMZ → Home | Deny   | VLAN 20 | VLAN 10     | Block all                 |
| Home → DMZ | Allow  | VLAN 10 | VLAN 20     | Required ports only       |
| Home → WAN | Allow  | VLAN 10 | Any         | Allow all                 |
| DMZ → WAN  | Allow  | VLAN 20 | Any         | Allow all                 |

## Port Forwarding (VLAN 20 — DMZ)

| Service    | Protocol / Port | Internal IP   |
|------------|-----------------|---------------|
| DMS Server | TCP 80, 443, 22 | 192.168.20.10 |
