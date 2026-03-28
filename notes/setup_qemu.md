# Host

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

# Guest

```bash
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean
sudo apt install -y qemu-guest-agent spice-vdagent mesa-utils spice-webdavd xserver-xorg-video-qxl
sudo systemctl --user enable --now spice-vdagent
sudo reboot
```

# Cursor fix in guest

```bash
echo "[*] Setting XFCE HiDPI cursor..."
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita"
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 48
xfconf-query -c xfwm4 -p /general/theme -s "Kali-Dark-xHiDPI"
xfconf-query -c xsettings -p /Net/ThemeName -s "Kali-Dark-xHiDPI"

echo "[*] Setting Xresources..."
cat > ~/.Xresources << 'XRES'
Xcursor.theme: Adwaita
Xcursor.size: 48
XRES

echo "[*] Setting session environment..."
cat >> ~/.xsessionrc << 'ENV'
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=48
ENV
```
# Disable compositor & Effects

```bash
xfconf-query -c xfwm4 -p /general/use_compositing -s false
xfconf-query -c xfwm4 -p /general/show_dock_shadow -s false
xfconf-query -c xfwm4 -p /general/show_frame_shadow -s false
xfconf-query -c xfwm4 -p /general/show_popup_shadow -s false
```

# Use zram

```bash
# Set swappiness to 10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
cat /proc/sys/vm/swappiness

sudo apt install zram-tools -y
echo 'ALGO=zstd' | sudo tee -a /etc/default/zramswap
echo 'PERCENT=25' | sudo tee -a /etc/default/zramswap
sudo systemctl enable zramswap
sudo systemctl start zramswap

# Verify
zramctl
```

# Fix scheduler
```bash
# Install linux-cpupower
sudo apt install linux-cpupower -y

# Set performance mode
sudo cpupower frequency-set -g performance

# Make permanent on boot
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpupower
sudo systemctl enable cpupower
```

# Use fstrim
```bash
sudo systemctl enable fstrim.timer && sudo systemctl start fstrim.timer
```

# FIx double click in kali
```bash
xfconf-query -c xsettings -p /Net/DoubleClickTime --create -t int -s 400
```

