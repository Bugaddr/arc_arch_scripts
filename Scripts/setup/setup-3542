#!/usr/bin/env bash

# Imp pkgs
pacman -S alacritty ripgrep fd man lm_sensors thermald ufw #r8168-lts r8168
pacman -S reflector xorg-xinit base-devel
pacman -S xorg-font-util xorg-mkfontscale
pacman -S macchanger
# Font pkg #ttf-lato ttf-fira-code inter-font
paru -S ttf-jetbrains-mono ttf-apple-emoji

# Extra pkg
pacman -S x86_energy_perf_policy asp vlc kate

# Disable broken UP key [Need xorg-xinit]
mkdir -pv /etc/X11/Xmodmap
echo -e 'keycode 98 = NoSymbol\nkeycode 115=' >/etc/X11/Xmodmap/Keyboard

# Pacman [Need reflector]
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i 's|#Color|Color|g' /etc/pacman.conf
sed -i 's|#VerbosePkgLists|VerbosePkgLists|g' /etc/pacman.conf
sed -i 's|#ParallelDownloads|ParallelDownloads|g' /etc/pacman.conf
reflector --latest 10 --sort rate --verbose --protocol https --save /etc/pacman.d/mirrorlist

# Journald
sed -i 's|#SystemMaxUse=|SystemMaxUse=50M|g' /etc/systemd/journald.conf
systemctl mask systemd-journald-audit.socket

# NetworkManager # Disable connectivity check
echo '[connectivity]
enabled=false' >/etc/NetworkManager/conf.d/20-connectivity.conf

# Firewall [Need ufw]
systemctl enable --now ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Nano [Need nano]
sed -i 's|# include|include|' /etc/nanorc

# Fix touchpad + nowatchdog + no nmi_watchdog
TEMPCL='GRUB_CMDLINE_LINUX_DEFAULT="i8042.nopnp=1 nowatchdog nmi_watchdog=0 quiet loglevel=0 audit=0"'
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|$TEMPCL|g" /etc/default/grub

# Grub config
sed -i 's|GRUB_TIMEOUT=5|GRUB_TIMEOUT=0|g' /etc/default/grub
sed -i 's|#GRUB_SAVEDEFAULT=true|GRUB_SAVEDEFAULT=true|g' /etc/default/grub
sed -i 's|GRUB_DEFAULT=0|GRUB_DEFAULT=saved|g' /etc/default/grub
sed -i 's|#GRUB_DISABLE_SUBMENU=y|GRUB_DISABLE_SUBMENU=y|g' /etc/default/grub
sed -i 's|GRUB_DISABLE_RECOVERY=true|GRUB_DISABLE_RECOVERY=false|g' /etc/default/grub
sed -i 's|#GRUB_DISABLE_OS_PROBER=false|GRUB_DISABLE_OS_PROBER=false|g' /etc/defaut/grub

# Disable root login
passwd -l root

# SwapFile
if [ -e /swapfile ]; then echo '/swapfile already exists, skiping'; else
	dd if=/dev/zero of=/swapfile count=4000 bs=1MB status=progress
	chmod -R 600 /swapfile
	echo -e '\n# Swap\n/swapfile swap swap defaults 0 0' >>/etc/fstab
	mkswap /swapfile && swapon /swapfile
fi

# Hibernation [Edit script if system is encrypted]
clear
read -rp 'Do you want to enable hibernation support? [Y/N]: ' HIBERYN
if [[ ${HIBERYN} =~ ^[Yy]$ ]]; then
	sed -i "s|HOOKS=(base.*|HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)|g" /etc/mkinitcpio.conf
	ROOTUUID="$(findmnt -no UUID -T /swapfile)"
	SWAPOFFSET="$(filefrag -v /swapfile | awk '{ if($1=="0:"){print substr($4, 1, length($4)-2)} }')"
	TEMPCMDL="GRUB_CMDLINE_LINUX_DEFAULT=\"resume=UUID=$ROOTUUID resume_offset=$SWAPOFFSET\""
	sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|$TEMPCMDL|g" /etc/default/grub
else exit; fi

# Use lz4 compression
sed -i 's|#COMPRESSION="lz4"|COMPRESSION="lz4"|g' /etc/mkinitcpio.conf

## Blacklist junk kernel modules.
read -rp "Blacklist some Junk kernel modules (y/n) " blacklistyn
if [ "${blacklistyn}" = "y" ]; then
	echo -e '# iTCO_wdt: disables watchdog
install iTCO_wdt /bin/true
install iTCO_vendor_support /bin/true
# joydev: disables joystick [Can be enabled with `modprobe joydev` in runtime for gaming]
install joydev /bin/true
# mousedev: disables PS2 mouse support that my laptop dont have a slot for
install mousedev /bin/true
# mac_hid: Apple relatedd stuff so blacklisting this
install mac_hid /bin/true' >/etc/modprobe.d/junk.conf
fi

# Disable r8169 to use r8168 # https://askubuntu.com/questions/1052971/r8168-r8169-realtek-driver-module-troubles
# Need r8168 or r8168-lts pkg
echo 'install r8169 /bin/true' /etc/modprobe.d/blacklist.conf

# Ipv6 privacy
sysctl -w net.ipv6.conf.all.use_tempaddr=2
sysctl -w net.ipv6.conf.default.use_tempaddr=2

# Randomize MAC address with networkmanager.
cat <<EOF >/etc/NetworkManager/conf.d/rand_mac.conf
[connection-mac-randomization]
ethernet.cloned-mac-address=random
wifi.cloned-mac-address=random
EOF

# Paru [Need git base-devel]
br && read -rp 'Do you want to install paru? [Y/N]: ' PARUYN
if [[ $PARUYN =~ ^[Yy]$ ]]; then
	git clone --depth=1 https://aur.archlinux.org/paru-bin.git ~/.cache/paru
	cd ~/.cache/paru
	makepkg -sic --noconfirm
	sed -i 's|#NewsOnUpgrade|NewsOnUpgrade|g' /etc/paru.conf
fi

# Better I/O scheduler
echo '
# set scheduler for NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# set scheduler for SSD and eMMC
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# set scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
' >/etc/udev/rules.d/60-ioschedulers.rules

# Enable audio powersave
echo "options snd_hda_intel power_save=1" >/etc/modprobe.d/audio_powersave.conf

# SATA powersaver
echo 'ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"' >/etc/udev/rules.d/hd_power_save.rules

# Fancontrol [Need lm_sensors]
sensors-detect --auto
sensors
pwmconfig
systemctl enable --now fancontrol
echo -e '\n# Fix hwmon path change\ncoretemp' >>/etc/modules-load.d/modules.conf

# auto-cpufreq

# Thermald
systemctl enable --now thermald

# Bluetooth
systemctl enable --now bluetooth

# Ending
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

### GPU DRIVERS
# nvidia [https://aur.archlinux.org/packages?O=0&SeB=nd&K=390xx&outdated=&SB=p&SO=d&PP=50&submit=Go]
paru -S --needed nvidia-390xx-{dkms,utils} lib32-nvidia-390xx-utils # Nvidia gpu driver
paru -S --needed nvidia-390xx-settings                              # Nvidia gpu setting [OPTIONAL]

# INTEL
pacman -S --needed xf86-video-intel # Intel gpu driver [Modesetting is better than this]

#######################
### GPU Switcher
# Optimus-manager [Remove other switcher & cleanup /etc/X11 & also remove bumblebee]
pacman -S --needed bbswitch-dkms #acpi_call-dkms
paru -S --needed optimus-manager
systemctl enable optimus-manager
sed -i 's|# Option|Option|g' /etc/optimus-manager/xorg/*-mode/*.conf # Enable default xorg option in optimus-manager configs

# Bumblebee [Remove other switcher & cleanup /etc/X11]
pacman -S --needed bbswitch-dkms
pacman -S --needed bumblebee
pacman -S --needed primus
systemctl enable bumblebeed
sed -i 's|#   BusID "PCI:01:00:0"|BusID "PCI:08:00:0"|g' /etc/bumblebee/xorg.conf.nvidia

########################
### OTHER GPU STUFF
# openGL # [Check mesa-amber & lib32-mesa-amber]
pacman -S --needed mesa lib32-mesa # open-source implementation of the OpenGL specification

# Vulkan # [Verify with vulkaninfo in vulkan-tools] # Fermi = NoVulkan
pacman -S --needed vulkan-icd-loader lib32-vulkan-icd-loader   # Vulkan Installable Client Driver (ICD) Loader
pacman -S --needed vulkan-intel lib32-vulkan-intel             # Intel's Vulkan driver
pacman -S --needed vulkan-mesa-layers lib32-vulkan-mesa-layers # Mesa's Vulkan layers
pacman -S --needed vkd3d lib32-vkd3d                           # Direct3D 12 to Vulkan translation library By WineHQ

########################
### HW VIDEO ACCLERATION
# VAAPI [check with vainfo in libva-utils package]
pacman -S --needed libva lib32-libva lib32-libva-mesa-driver   # VA-API for linux
pacman -S --needed libva-intel-driver lib32-libva-intel-driver # VA-API driver for intel
#paru -S --needed libva-intel-driver-hybrid intel-hybrid-codec-driver # Modified libva-intel-driver to support Haswell 8-bit HEVC/h.265 decoding

# VDPAU  [check with vdpauinfo]
pacman -S --needed libvdpau lib32-libvdpau

# VDPAU on VAAPI Translation layers
pacman -S --needed libva-vdpau-driver lib32-libva-vdpau-driver # VDPAU-based backend for VA-API
pacman -S --needed libvdpau-va-gl                              # VDPAU driver with OpenGL/VAAPI backend. H.264 only
#paru -S --needed libva-nvidia-driver                          # CUDA NVDECODE based backend for VAAPI (Need cuda) [Conflict: libva-vdpau-driver]
pacman -S --needed mesa-vdpau lib32-mesa-vdpau # Mesa VDPAU drivers

# Env variable for VDPAU/VAAPI/VULKAN
echo 'if [[ "$(optimus-manager --print-mode)" =~ 'nvidia' ]]; then
    export LIBVA_DRIVER_NAME='nvidia' # /usr/lib/dri/${LIBVA_DRIVER_NAME}_drv_video.so
    export VDPAU_DRIVER='nvidia'      # /usr/lib/vdpau/libvdpau_${VDPAU_DRIVER}.so
    #export VK_ICD_FILENAMES='/usr/share/vulkan/icd.d/nvidia_icd.json'
elif [[ "$(optimus-manager --print-mode)" =~ 'integrated' ]]; then
    export LIBVA_DRIVER_NAME='i965'
    export VDPAU_DRIVER='va_gl'
    export VK_ICD_FILENAMES='/usr/share/vulkan/icd.d/intel_icd.x86_64.json'
fi' >/etc/profile.d/env.sh

### INTEL GPU STUFF
# Enable framebuffer compression & Fastboot [For intel gpu >6-gen]
echo -e 'options i915 enable_fbc=1 fastboot=1' >/etc/modprobe.d/i915.conf

### EXTRA LIBS/PKGS FOR GRAPHIC
pacman -S --needed libglvnd lib32-libglvnd # The GL Vendor-Neutral Dispatch library E.g provides libegl

### CPU Microcode
pacman -S intel-ucode

# EXTRA JUNK
# adriconf

# SOME INFO
# CREDIT: https://www.reddit.com/r/archlinux/comments/n5ypqh/eli5_intel_graphic_drivers/
# D3D = Proprietary 2D & 3D graphic Api for windows
# openGL = Open source 2D & 3D graphic Api
# Vulkan = Modern sucessor of openGL & D3D
# MESA = Libs for base-gpu-rendering, openGL & Vulkan
# XF86-video-* = xf86-video-* packages drivers to enable hardware 2D acceleration in Xorg using vendor-specific code
# Vulkan-extra-layers,vulkan-validation-layers are for development stuff
# VDPAU
# VAAPI
#
#
#
#

# NOTES
# lib32-libva-intel-driver & lib32-libva-vdpau-driver are outdated
