# Installation

```bash
pacman -S --needed qemu-desktop virt-manager virt-viewer dnsmasq virglrenderer
systemctl enable --now libvirtd

usermod -aG libvirt,kvm $USER # Run as normal user
newgrp libvirt

virsh net-destroy default
virsh net-start default
virsh net-autostart default

sudo ufw allow in on virbr0
sudo ufw allow out on virbr0
ufw reload
```

## In VM

```bash
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean
sudo apt install -y qemu-guest-agent spice-vdagent mesa-utils
sudo systemctl --user enable --now spice-vdagent
```
