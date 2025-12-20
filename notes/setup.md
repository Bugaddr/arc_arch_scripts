# Arch Linux Post-Install Configuration Guide

## Restore my dotfiles

```bash
git clone --bare git@github.com:Bugaddr/linux_dotfiles.git $HOME/.dotfiles
alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
mkdir -p ~/.dotfiles-backup && dot checkout 2>&1 | awk '/^\s+\./{print $1}' | xargs -I{} sh -c 'mkdir -p ~/.dotfiles-backup/$(dirname "{}") && mv ~/"{}" ~/.dotfiles-backup/"{}"'
dot checkout
dot config --local status.showUntrackedFiles no
```

## Swap

```bash
# 1. Install ZRAM generator
pacman -S --needed --noconfirm zram-generator

# 2. Configure ZRAM (50% RAM, High Priority)
cat <<'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

# 3. Optimize VM parameters for ZRAM
cat <<'EOF' > /etc/sysctl.d/99-zram.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

# 4. Create 4GB Fallback Swapfile (Low Priority)
SWAP_SIZE=4G
SWAP_FILE="/swapfile"

# Handle Btrfs CoW specific requirements
if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
    truncate -s 0 "$SWAP_FILE"
    chattr +C "$SWAP_FILE"
    btrfs property set "$SWAP_FILE" compression none
fi

dd if=/dev/zero of="$SWAP_FILE" bs=1G count=4 status=progress
chmod 600 "$SWAP_FILE"
mkswap "$SWAP_FILE"
swapon "$SWAP_FILE"

# 5. Persistence
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap defaults,pri=0 0 0" >> /etc/fstab
fi

# 6. Disable ZSwap to prevent conflicts
echo 0 > /sys/module/zswap/parameters/enabled
if [[ -f /etc/kernel/cmdline ]]; then
  if ! grep -q "zswap.enabled=0" /etc/kernel/cmdline; then
      sed -i '$ s/$/ zswap.enabled=0/' /etc/kernel/cmdline
  fi
fi

# 7. Start Services
systemctl daemon-reload
systemctl start systemd-zram-setup@zram0.service
```

## Configure pacman

```bash
pacman -S --needed --noconfirm reflector
mkdir -p /etc/xdg/reflector
cat <<'EOF' > /etc/xdg/reflector/reflector.conf
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 20
--age 24
--country IN,SG
--sort rate
--verbose
EOF
systemctl enable --now reflector.timer

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
fi
sed -i 's|^#Color|Color|' /etc/pacman.conf
sed -i 's|^#VerbosePkgLists|VerbosePkgLists|' /etc/pacman.conf
sed -i 's|^#ParallelDownloads = 5|ParallelDownloads = 10|' /etc/pacman.conf
```

## SSD

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
cat <<'EOF' > /etc/NetworkManager/conf.d/custom.conf
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

## Cmdline

```bash
if [[ -f /etc/kernel/cmdline ]]; then
  if ! grep -Fq "acpi_backlight=native" /etc/kernel/cmdline; then
    sed -i 's|$| acpi_backlight=native|' /etc/kernel/cmdline
  fi
  if ! grep -Fq "acpi_osi=!" /etc/kernel/cmdline; then
    sed -i 's|$| acpi_osi=!|' /etc/kernel/cmdline
  fi
  if ! grep -Fq 'acpi_osi="Windows 2021"' /etc/kernel/cmdline; then
    sed -i 's|$| acpi_osi="Windows 2021"|' /etc/kernel/cmdline
  fi
  if ! grep -Fq "sysrq_always_enabled=1" /etc/kernel/cmdline; then
    sed -i 's|$| sysrq_always_enabled=1|' /etc/kernel/cmdline
  fi
  mkinitcpio -P
fi
```

## NVIDIA GPU

```bash
tee /etc/modprobe.d/nvidia_suspend_fix.conf << 'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF

if lspci | grep -i nvidia &>/dev/null; then
  pacman -S --needed nvidia libva-nvidia-driver

  systemctl unmask nvidia-suspend
  systemctl enable nvidia-suspend

  systemctl unmask nvidia-resume
  systemctl enable nvidia-resume

  systemctl unmask nvidia-hibernate
  systemctl enable nvidia-hibernate

  systemctl unmask nvidia-powerd
  systemctl enable nvidia-powerd
fi
```

## Intel GPU

```bash
pacman -S --needed --noconfirm intel-media-driver libvdpau-va-gl \
  vulkan-icd-loader vulkan-intel vulkan-mesa-layers vpl-gpu-rt
cat <<'EOF' > /etc/environment
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

## Power management

```bash
pacman -S --needed --noconfirm power-profiles-daemon
systemctl daemon-reload
systemctl enable --now power-profiles-daemon
```

## SDDM

```bash
mkdir -p /etc/sddm.conf.d
install -Dm644 /dev/stdin /etc/sddm.conf.d/10-wayland-hidpi.conf <<'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_SCREEN_SCALE_FACTORS=1.5,QT_FONT_DPI=144
[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
EOF
```

## Create consistent device paths for GPU

```bash
cat <<EOF | sudo tee /etc/udev/rules.d/99-gpu-paths.rules
# Intel Integrated GPU (iGPU) - Vendor: 0x8086, Matches the primary display controller and the render node for QuickSync/VA-API
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", KERNELS=="0000:00:02.0", KERNEL=="card*", SYMLINK+="dri/intel-igpu"
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", KERNELS=="0000:00:02.0", KERNEL=="renderD*", SYMLINK+="dri/intel-igpu-render"

# NVIDIA Discrete GPU (dGPU) - Vendor: 0x10de, Matches the primary controller and the render node for CUDA/NVENC/Optimus
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x10de", KERNELS=="0000:01:00.0", KERNEL=="card*", SYMLINK+="dri/nvidia-dgpu"
SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x10de", KERNELS=="0000:01:00.0", KERNEL=="renderD*", SYMLINK+="dri/nvidia-dgpu-render"
EOF
udevadm control --reload-rules
udevadm trigger
ls -l /dev/dri/ | grep -E "igpu|dgpu"
```

## Enable secure boot

1. Install sbctl

    ```bash
    pacman -S --needed sbctl
    ```

2. Create keys

    ```bash
    sbctl create-keys
    ```

3. Enter UEFI setup and change secure boot mode to custom (Clear all other keys, dont factory reset, disable secure boot)

    ```bash
    systemctl reboot --firmware-setup
    ```

4. Enroll with Microsoft keys

    ```bash
    sbctl enroll-keys -m
    ```

5. Sign unsigned binaries !!

    ```bash
    sbctl verify | awk '/EFI\/(Linux|systemd|Boot)\/.* is not signed$/ {print $2}' | xargs -r sbctl sign -s
    ```

## Enable TPM2

1. Install lvm2
    ```bash
    pacman -S --needed lvm2
    ```
2. Add this hooks to /etc/mkinitcpio.conf

    ```text
    HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)
    ```

3. Generate recovery key of encrypted disk
    ```bash
    systemd-cryptenroll --recovery-key /dev/nvme0n1p5
    ```
4. Add TPM key
    ```bash
    systemd-cryptenroll /dev/nvme0n1p5 --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7
    ````
5. Modify `/etc/crypttab.initramfs`
    ```bash
    UUID=$(cryptsetup luksUUID /dev/nvme0n1p5)
    echo "root UUID=$UUID none tpm2-device=auto" | tee /etc/crypttab.initramfs
    ```
6. Recreate initramfs `mkinitcpio -P`
