## https://www.walian.co.uk/

## Make UKI
# Add commandline to /etc/kernel/cmdline (Fix partuuid)
echo 'cryptdevice=PARTUUID=b82b63ef-1a8c-4e50-8ede-67a3655093ea:root root=/dev/mapper/root zswap.enabled=0 rootflags=subvol=archroot rw rootfstype=btrfs acpi_backlight=native' >/mnt/etc/kernel/cmdline

# Edit preset file (Need to be done for every new kernel install)
cat << 'EOF' >/etc/mkinitcpio.d/linux-lts.preset
# mkinitcpio preset file for the 'linux-lts' package

#ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux-lts.img"
default_uki="/boot/EFI/Linux/arch-linux-lts.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-lts-fallback.img"
fallback_uki="/boot/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
EOF

# Generate uki
mkdir -p /boot/EFI/Linux
mkinitcpio -P



## Secure boot
# Create keys
sbctl create-keys

# Enroll keys
sbctl enroll-keys -m

# Sign files for first time, next time use 'sbctl sign-all' or any pacman hook (Needs to be done after every new kernel or microcode install)
sbctl verify | sed 's/✗ /sbctl sign -s \//e'

# Check status
sbctl status

# Add mkinitcpio hook to sign uki (Usefull for when we update wireless-regdb or firmware files but pacman hook dont run, so better run it as mkinitcpio hook) 
# (Use it till sbctl next update only, and keep checking sbctl issues section)
cat << 'EOF' >/etc/initcpio/post/sbctl-sign
#!/usr/bin/bash

uki="$3"
[[ -n "$uki" ]] || exit 0
sbctl sign -s "$uki"
EOF
chmod +x /etc/initcpio/post/sbctl-sign



## Add UEFI entry (Needed to create after every new kernel install)
efibootmgr --create --disk /dev/nvme0n1 --part 5 --label "Arch (linux-lts)" --loader '\EFI\Linux\arch-linux-lts.efi' --unicode
efibootmgr --create --disk /dev/nvme0n1 --part 5 --label "Arch (linux-lts-fallback)" --loader '\EFI\Linux\arch-linux-lts-fallback.efi' --unicode
