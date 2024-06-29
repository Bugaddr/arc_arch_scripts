# Installation

```bash
pacman -S --needed qemu-desktop virt-manager virt-viewer dnsmasq
systemctl enable libvirtd
virsh net-autostart default
virsh net-start default 
```

## In VM

1. add spicevmc channel
2. Install qemu-guest-agent & spice-vdagent in vm

```bash
sudo apt install qemu-guest-agent spice-vdagent
```
