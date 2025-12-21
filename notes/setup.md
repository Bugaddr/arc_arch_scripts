### Arch Linux Post-Install Guide

## Restore my dotfiles

```bash
git clone --bare git@github.com:Bugaddr/linux_dotfiles.git $HOME/.dotfiles
alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Safely checkout and backup existing files
mkdir -p ~/.dotfiles-backup
dot checkout 2>&1 | awk '/^\s+\./{print $1}' | xargs -I{} sh -c 'mkdir -p ~/.dotfiles-backup/$(dirname "{}") && mv ~/"{}" ~/.dotfiles-backup/"{}"'

dot checkout
dot config --local status.showUntrackedFiles no

```

## Swap & ZRAM (Fixed)

```bash
# 1. Install ZRAM generator
pacman -S --needed --noconfirm zram-generator

# 2. Configure ZRAM (Priority 100 = High)
cat <<EOF | tee /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

# 3. Optimize VM parameters
# Fixed: Lowered swappiness from 180 to 100 to prevent disk thrashing
# if ZRAM fills up. 100 is still aggressive enough to use ZRAM effectively.
cat <<EOF | tee /etc/sysctl.d/99-zram.conf
vm.swappiness = 100
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

# 4. Create Swapfile (Fallback)
SWAP_SIZE=4G
SWAP_FILE="/swapfile"

# Handle Btrfs CoW specific requirements
# (Critical: +C must be set on an empty file before writing data)
if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
    truncate -s 0 "$SWAP_FILE"
    chattr +C "$SWAP_FILE"
    btrfs property set "$SWAP_FILE" compression none
fi

# Create and Activate
dd if=/dev/zero of="$SWAP_FILE" bs=1G count=4 status=progress
chmod 600 "$SWAP_FILE"
mkswap "$SWAP_FILE"
swapon "$SWAP_FILE"

# 5. Persistence
# Fixed: Set priority to -2 (lowest) to ensure ZRAM (100) is always filled first.
if ! grep -q "/swapfile" /etc/fstab; then
cat <<EOF | tee -a /etc/fstab
/swapfile none swap defaults,pri=-2 0 0
EOF
fi

# 6. Disable ZSwap (Prevent conflict with ZRAM)
echo 0 | tee /sys/module/zswap/parameters/enabled

# 7. Start Services
systemctl daemon-reload
systemctl start systemd-zram-setup@zram0.service
```

## Configure pacman

```bash
pacman -S --needed --noconfirm reflector
mkdir -p /etc/xdg/reflector

# Reflector configuration (Overwrite)
cat <<EOF | tee /etc/xdg/reflector/reflector.conf
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 20
--age 24
--country IN,SG
--sort rate
--verbose
EOF
systemctl enable --now reflector.timer

# Pacman.conf adjustments (In-place sed is still required here)
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
fi
sed -i 's|^#Color|Color|' /etc/pacman.conf
sed -i 's|^#VerbosePkgLists|VerbosePkgLists|' /etc/pacman.conf
sed -i 's|^#ParallelDownloads = 5|ParallelDownloads = 10|' /etc/pacman.conf

```

## SSD Maintenance

```bash
systemctl enable --now fstrim.timer

```

## Firewall

```bash
pacman -S --needed --noconfirm ufw
systemctl enable --now ufw
ufw --force default deny incoming
ufw --force default allow outgoing
ufw --force enable

```

## DoH + NetworkManager

```bash
pacman -S --needed --noconfirm dns-over-https
mkdir -p /etc/NetworkManager/conf.d

# NetworkManager Configuration (Overwrite)
cat <<EOF | tee /etc/NetworkManager/conf.d/custom.conf
[global-dns-domain-*]
servers=127.0.0.1
[connection]
ipv4.dhcp-send-hostname=0
ipv6.dhcp-send-hostname=0
ipv6.ip6-privacy=2
[connection-mac-randomization]
ethernet.cloned-mac-address=random
wifi.cloned-mac-address=random
EOF

systemctl unmask doh-client
systemctl enable --now doh-client
systemctl start doh-client
systemctl restart NetworkManager

```

## Wireless REGDB

```bash
pacman -S --needed --noconfirm wireless-regdb

if [[ -f /etc/conf.d/wireless-regdom ]]; then
    sed -i 's/^#WIRELESS_REGDOM="IN"/WIRELESS_REGDOM="IN"/' /etc/conf.d/wireless-regdom
fi
iw reg set IN

```

## Kernel Cmdline

```bash
# Helper function for idempotency
add_param() {
    if [[ -f /etc/kernel/cmdline ]] && ! grep -q "$1" /etc/kernel/cmdline; then
        sed -i "s/$/ $1/" /etc/kernel/cmdline
        echo "Added parameter: $1"
    fi
}

add_param 'sysrq_always_enabled=1'
add_param 'acpi_backlight=native'
add_param 'acpi_osi=!'
add_param 'acpi_osi="Windows 2021"'

mkinitcpio -P

```

## NVIDIA GPU

```bash
# Modprobe configuration (Overwrite)
cat <<EOF | tee /etc/modprobe.d/nvidia_suspend_fix.conf
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF

if lspci | grep -i nvidia &>/dev/null; then
    pacman -S --needed nvidia-open libva-nvidia-driver

    systemctl unmask nvidia-suspend && systemctl enable nvidia-suspend
    systemctl unmask nvidia-resume && systemctl enable nvidia-resume
    systemctl unmask nvidia-hibernate && systemctl enable nvidia-hibernate
    systemctl unmask nvidia-powerd && systemctl enable nvidia-powerd
fi

```

## Intel GPU

```bash
pacman -S --needed --noconfirm intel-media-driver libvdpau-va-gl \
  vulkan-icd-loader vulkan-intel vulkan-mesa-layers vpl-gpu-rt

# Environment variables (Overwrite)
cat <<EOF | tee /etc/environment
LIBVA_DRIVER_NAME=iHD
VDPAU_DRIVER=va_gl
EOF

```

## Intel CPU

```bash
pacman -S --needed --noconfirm thermald
sensors-detect --auto
systemctl daemon-reload
systemctl enable --now thermald

```

## Power Management

```bash
pacman -S --needed --noconfirm power-profiles-daemon
systemctl daemon-reload
systemctl enable --now power-profiles-daemon

```

## SDDM

```bash
mkdir -p /etc/sddm.conf.d

# SDDM Wayland config (Overwrite)
cat <<EOF | tee /etc/sddm.conf.d/10-wayland-hidpi.conf
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_SCREEN_SCALE_FACTORS=1.5,QT_FONT_DPI=144

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
EOF

```

## Create consistent device paths for GPU

```bash
# Udev rules (Overwrite)
cat <<EOF | tee /etc/udev/rules.d/99-gpu-paths.rules
# Intel Integrated GPU (iGPU) - Vendor: 0x8086
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", KERNELS=="0000:00:02.0", KERNEL=="card*", SYMLINK+="dri/intel-igpu"
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", KERNELS=="0000:00:02.0", KERNEL=="renderD*", SYMLINK+="dri/intel-igpu-render"

# NVIDIA Discrete GPU (dGPU) - Vendor: 0x10de
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x10de", KERNELS=="0000:01:00.0", KERNEL=="card*", SYMLINK+="dri/nvidia-dgpu"
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x10de", KERNELS=="0000:01:00.0", KERNEL=="renderD*", SYMLINK+="dri/nvidia-dgpu-render"
EOF

udevadm control --reload-rules
udevadm trigger

```

## Enable secure boot

1. **Install & Setup**
```bash
pacman -S --needed sbctl
sbctl create-keys

```


2. **Reboot & Enroll**
```bash
# Run this manually
systemctl reboot --firmware-setup
# In BIOS: Enable Secure Boot, Mode: Custom, Clear Keys

```


3. **Enroll & Sign**
```bash
sbctl enroll-keys -m
sbctl verify | awk '/EFI\/(Linux|systemd|Boot)\/.* is not signed$/ {print $2}' | xargs -r sbctl sign -s

```



## Enable TPM2

1. **Install**
```bash
pacman -S --needed lvm2 tpm2-tools

```


2. **Hooks**
```bash
# Update Hooks like this
HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)
```


3. **Enroll**
```bash
systemd-cryptenroll --recovery-key /dev/nvme0n1p5
systemd-cryptenroll /dev/nvme0n1p5 --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7

```


4. **Crypttab (Overwrite)**
```bash
UUID=$(cryptsetup luksUUID /dev/nvme0n1p5)
cat <<EOF | tee /etc/crypttab.initramfs
root UUID=$UUID none tpm2-device=auto
EOF

```


5. **Finalize**
```bash
mkinitcpio -P

```
