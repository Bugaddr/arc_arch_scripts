# Installation

```bash
pacman -S --needed qemu-desktop virt-manager virt-viewer dnsmasq virglrenderer
systemctl enable --now libvirtd # Run as normal user
usermod -aG libvirt,kvm $USER
newgrp libvirt
virsh net-start default
virsh net-autostart default
```

## In VM

1. Add spicevmc channel in virt-manager settings
2. Install this in vm

```bash
sudo apt install -y qemu-guest-agent spice-vdagent mesa-utils
sudo systemctl --user enable --now spice-vdagent
```
