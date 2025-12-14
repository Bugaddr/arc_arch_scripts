# Arch Linux Post-Install Configuration Guide

## Restore my dotfiles

```bash
git clone --bare git@github.com:Bugaddr/linux_dotfiles.git $HOME/.dotfiles
alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
mkdir -p ~/.dotfiles-backup && dot checkout 2>&1 | awk '/^\s+\./{print $1}' | xargs -I{} sh -c 'mkdir -p ~/.dotfiles-backup/$(dirname "{}") && mv ~/"{}" ~/.dotfiles-backup/"{}"'
dot checkout
dot config --local status.showUntrackedFiles no
```

## Configure pacman

```bash
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
fi
sed -i 's|^#Color|Color|' /etc/pacman.conf
sed -i 's|^#VerbosePkgLists|VerbosePkgLists|' /etc/pacman.conf
sed -i 's|^#ParallelDownloads = 5|ParallelDownloads = 10|' /etc/pacman.conf
```

## Setup reflector

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
```

## Enable UFW

```bash
pacman -S --needed --noconfirm ufw
systemctl enable --now ufw
ufw --force default deny incoming
ufw --force default allow outgoing
ufw --force enable
```

## NetworkManager [Hardening]

```bash
mkdir -p /etc/NetworkManager/conf.d
cat <<'EOF' > /etc/NetworkManager/conf.d/custom.conf
[connection]
ipv4.dhcp-send-hostname=0
ipv6.dhcp-send-hostname=0
ipv6.ip6-privacy=2
[connection-mac-randomization]
ethernet.cloned-mac-address=random
wifi.cloned-mac-address=random
EOF
systemctl restart NetworkManager
```

## Setup DNS-over-HTTPS

```bash
pacman -S --needed --noconfirm dns-over-https
systemctl unmask doh-client
systemctl enable --now doh-client
mkdir -p /etc/NetworkManager/conf.d
cat <<'EOF' > /etc/NetworkManager/conf.d/doh.conf
[global-dns-domain-*]
servers=127.0.0.1
EOF
systemctl restart NetworkManager
```

## Configure wireless regdb

```bash
pacman -S --needed --noconfirm wireless-regdb
if [[ -f /etc/conf.d/wireless-regdom ]]; then
  sed -i 's/^#WIRELESS_REGDOM="IN"/WIRELESS_REGDOM="IN"/' /etc/conf.d/wireless-regdom
fi
iw reg set IN
```

## Fix backlight

```bash
if [[ -f /etc/kernel/cmdline ]]; then
  if ! grep -q "acpi_backlight=native" /etc/kernel/cmdline; then
    sed -i 's/$/ acpi_backlight=native acpi_osi=! acpi_osi=\"Windows 2021\"/' /etc/kernel/cmdline
    mkinitcpio -P
  fi
fi
```

## Enable SysRq

```bash
if [[ -f /etc/kernel/cmdline ]]; then
  if ! grep -q "sysrq_always_enabled=1" /etc/kernel/cmdline; then
      sed -i '$ s/$/ sysrq_always_enabled=1/' /etc/kernel/cmdline
  fi
fi
```

## NVIDIA GPU drivers

```bash
tee /etc/modprobe.d/nvidia_suspend_fix.conf << 'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
options nvidia NVreg_EnableGpuFirmware=0
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

## Intel GPU drivers

```bash
pacman -S --needed --noconfirm intel-media-driver libvdpau-va-gl \
  vulkan-icd-loader vulkan-intel vulkan-mesa-layers vpl-gpu-rt
cat <<'EOF' > /etc/environment
LIBVA_DRIVER_NAME=iHD
VDPAU_DRIVER=va_gl
EOF
```

## Power management & thermald

```bash
pacman -S --needed --noconfirm power-profiles-daemon thermald
systemctl daemon-reload
sensors-detect --auto
systemctl enable --now power-profiles-daemon thermald
```

## Fix keyboard keys

```bash
tee /etc/udev/hwdb.d/90-acer-nitro5-an515-58.hwdb > /dev/null << 'EOF'
evdev:atkbd:dmi:bvn*:bvr*:bd*:svnAcer*:pnNitro*AN*515-58:pvr*
 KEYBOARD_KEY_ef=kbdillumup
 KEYBOARD_KEY_f0=kbdillumdown
EOF
systemd-hwdb update
udevadm trigger --sysname-match="event*"
```

## SDDM

```bash
mkdir -p /etc/sddm.conf.d
sudo install -Dm644 /dev/stdin /etc/sddm.conf.d/10-wayland-hidpi.conf <<'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_SCREEN_SCALE_FACTORS=1.5,QT_FONT_DPI=144
[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
EOF
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
