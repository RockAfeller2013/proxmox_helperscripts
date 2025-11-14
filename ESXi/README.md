- VMware ESXi 8.0 Update 3e now available as a Free Hypervisor - https://knowledge.broadcom.com/external/article/399823/vmware-esxi-80-update-3e-now-available-a.html

```
cat /sys/module/kvm_intel/parameters/nested

```

The following configuration works;
```
qm config 4000
bios: seabios
boot: order=sata0
cores: 4
cpu: host
ide2: none,media=cdrom
memory: 33000
meta: creation-qemu=10.0.2,ctime=1763091899
name: ESXI
net0: vmxnet3=BC:24:11:81:A5:04,bridge=vmbr0
numa: 0
ostype: other
sata0: local-lvm:vm-4000-disk-0,size=100G
scsihw: pvscsi
smbios1: uuid=94b63b6e-21c0-4c0b-b960-edef02a85d02
sockets: 2
vcpus: 4
vga: std
vmgenid: 08f98fd5-1bba-4a7a-8915-8cec58caedc9
```

```
qm create 4000 \
  --name ESXI \
  --bios seabios \
  --boot order=sata0 \
  --cores 4 \
  --cpu host \
  --memory 32000 \
  --numa 0 \
  --ostype other \
  --scsihw pvscsi \
  --sockets 2 \
  --vcpus 4 \
  --vga std

qm set 4000 --net0 vmxnet3,bridge=vmbr0
qm set 4000 --ide2 none,media=cdrom
qm set 4000 --sata0 local-lvm:100,format=raw,size=100G
qm set 4000 --scsi1 local-lvm:200


```

- https://forum.proxmox.com/threads/can-i-run-vmware-in-proxmox.114009/
- https://iriarte.it/homelab/2023/09/05/esxi-on-proxmox-as-nested-hypervisor.html
- https://williamlam.com/nested-virtualization/nested-esxi-virtual-appliance
- https://williamlam.com/nested-virtualization#google_vignette
- https://devopstales.github.io/virtualization/install-vmware-in-proxmox/
- https://gist.github.com/bgulla/2421b589de4b4b75e83ac79b17f0fc85
- https://kiwicloud.ninja/2024/01/building-a-nested-proxmox-pve-cluster-on-esxi-part-1/
- https://forum.proxmox.com/threads/nested-esxi-8-0-on-pve-8-0-host.134818/
- https://forum.proxmox.com/threads/nested-virtualization-esxi-8-0-running-on-pve-8.133254/
- https://iriarte.it/homelab/2023/09/05/esxi-on-proxmox-as-nested-hypervisor.html
- https://williamlam.com/2025/05/vmware-flings-is-now-available-in-free-downloads-of-broadcom-support-portal-bsp.html
- https://www.xda-developers.com/i-virtualized-esxi-using-proxmox-and-it-works-better-than-i-expected/

