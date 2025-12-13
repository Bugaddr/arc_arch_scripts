# Installation

```bash
pacman -S --needed qemu-desktop virt-manager virt-viewer dnsmasq virglrenderer
systemctl enable --now libvirtd

usermod -aG libvirt,kvm $USER # Run as normal user
newgrp libvirt

virsh net-destroy default
virsh net-start default
virsh net-autostart default

ufw allow in on virbr0 from any to any
ufw reload
```

## In VM

```bash
echo -e "\n[global-dns]\nservers=8.8.8.8,1.1.1.1" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
sudo sed -i '/^\[main\]/a dns=none' /etc/NetworkManager/NetworkManager.conf
sudo systemctl restart NetworkManager

sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean
sudo apt install -y qemu-guest-agent spice-vdagent mesa-utils
sudo systemctl --user enable --now spice-vdagent
```
