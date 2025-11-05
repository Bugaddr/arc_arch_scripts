#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Check root privileges
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }

# Install base packages
pacman -Syu --needed --noconfirm \
  ttf-jetbrains-mono-nerd firefox fd ripgrep tree \
  nano-syntax-highlighting man-db wl-clipboard spectacle noto-fonts-emoji

# Configure pacman
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
fi
sed -i 's|^#Color|Color|' /etc/pacman.conf
sed -i 's|^#VerbosePkgLists|VerbosePkgLists|' /etc/pacman.conf
sed -i 's|^#ParallelDownloads = 5|ParallelDownloads = 10|' /etc/pacman.conf
pacman -Sy

# Setup mirrorlist with reflector
pacman -S --needed --noconfirm reflector
mkdir -p /etc/xdg/reflector
cat <<'EOF' >/etc/xdg/reflector/reflector.conf
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 20
--age 12
--country IN,SG
--sort rate
--verbose
EOF
systemctl enable --now reflector.timer

# Configure firewall
pacman -S --needed --noconfirm ufw
systemctl enable --now ufw
ufw --force default deny incoming
ufw --force default allow outgoing
ufw --force enable

# Configure NetworkManager
mkdir -p /etc/NetworkManager/conf.d
cat <<'EOF' >/etc/NetworkManager/conf.d/custom.conf
[connection]
ipv6.ip6-privacy=2

[connection-mac-randomization]
ethernet.cloned-mac-address=random
wifi.cloned-mac-address=random
EOF

# Setup Bluetooth
pacman -S --needed --noconfirm bluez bluez-utils
systemctl enable --now bluetooth

# Configure backlight
if [[ -f /etc/kernel/cmdline ]]; then
  if ! grep -q "acpi_backlight=native" /etc/kernel/cmdline; then
    sed -i 's/$/ acpi_backlight=native/' /etc/kernel/cmdline
    mkinitcpio -P
  fi
fi

# Setup DNS-over-HTTPS
pacman -S --needed --noconfirm dns-over-https
systemctl unmask doh-client
systemctl enable --now doh-client
mkdir -p /etc/NetworkManager/conf.d
cat <<'EOF' >/etc/NetworkManager/conf.d/dns-servers.conf
[global-dns-domain-*]
servers=127.0.0.1
EOF

# Setup NVIDIA drivers
if lspci | grep -i nvidia &>/dev/null; then
  pacman -S --needed --noconfirm nvidia-open
  systemctl unmask nvidia-resume nvidia-suspend nvidia-hibernate nvidia-powerd
  systemctl enable --now nvidia-resume nvidia-suspend nvidia-hibernate nvidia-powerd
fi

# Setup GPU acceleration
pacman -S --needed --noconfirm \
  intel-media-driver libva-nvidia-driver libvdpau-va-gl \
  vulkan-icd-loader vulkan-intel vulkan-mesa-layers

# Configure wireless regulatory domain
pacman -S --needed --noconfirm wireless-regdb
if [[ -f /etc/conf.d/wireless-regdom ]]; then
  sed -i 's/^#WIRELESS_REGDOM=.*/WIRELESS_REGDOM="BO"/' /etc/conf.d/wireless-regdom
fi

# Setup power management
pacman -S --needed --noconfirm power-profiles-daemon
systemctl daemon-reload
systemctl enable --now power-profiles-daemon

# Configure auto kwallet unlock
sudo cp /etc/pam.d/system-login /etc/pam.d/system-login.bak.$(date +%Y%m%d%H%M%S)
sudo sed -i '/^auth[[:space:]]\+include[[:space:]]\+system-auth/a auth     optional  pam_kwallet6.so try_first_pass' /etc/pam.d/system-login
grep -q pam_systemd.so /etc/pam.d/system-login && sudo sed -i '/pam_systemd.so/i session  optional  pam_kwallet6.so auto_start' /etc/pam.d/system-login || \
  echo 'session  optional  pam_kwallet6.so auto_start' | sudo tee -a /etc/pam.d/system-login
