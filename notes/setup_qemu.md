# Installation

```bash
pacman -S --needed qemu-desktop virt-manager virt-viewer dnsmasq virglrenderer
systemctl enable --now libvirtd

usermod -aG libvirt,kvm $USER # Run as normal user
newgrp libvirt

virsh net-start default
virsh net-autostart default

ufw allow in on virbr0 from any to any
ufw reload
```

## In VM

1. Add spicevmc channel in virt-manager settings
2. Install this in vm

```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
sudo apt install -y qemu-guest-agent spice-vdagent mesa-utils
sudo systemctl --user enable --now spice-vdagent
```
