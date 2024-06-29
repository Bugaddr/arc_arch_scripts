#!/usr/bin/env bash

# Enable audio powersave
echo "options snd_hda_intel power_save=1" >/etc/modprobe.d/audio_powersave.conf

# SATA powersaver
echo 'ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"' >/etc/udev/rules.d/hd_power_save.rules

# Set Network Manager iwd backend [Better than wpasupplicant]
cat <<EOF >>/etc/NetworkManager/conf.d/nm.conf
[device]
wifi.backend=iwd
EOF

# Better I/O scheduler
cat <<EOF >/etc/udev/rules.d/60-ioschedulers.rules
# set scheduler for NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# set scheduler for SSD and eMMC
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# set scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF

# Optimize Makepkg
sed -i 's/^CFLAGS.*/CFLAGS="-march=native -mtune=native -O2 -pipe -fstack-protector-strong --param=ssp-buffer-size=4 -fno-plt"/' /etc/makepkg.conf
sed -i 's/^CXXFLAGS.*/CXXFLAGS="-march=native -mtune=native -O2 -pipe -fstack-protector-strong --param=ssp-buffer-size=4 -fno-plt"/' /etc/makepkg.conf
sed -i 's/^#RUSTFLAGS.*/RUSTFLAGS="-C opt-level=2 -C target-cpu=native"/' /etc/makepkg.conf
sed -i 's/^#BUILDDIR.*/BUILDDIR=\/tmp\/makepkg/' /etc/makepkg.conf
sed -i 's/^#MAKEFLAGS.*/MAKEFLAGS="-j$(getconf _NPROCESSORS_ONLN) --quiet"/' /etc/makepkg.conf
sed -i 's/^COMPRESSGZ.*/COMPRESSGZ=(pigz -c -f -n)/' /etc/makepkg.conf
sed -i 's/^COMPRESSBZ2.*/COMPRESSBZ2=(pbzip2 -c -f)/' /etc/makepkg.conf
sed -i 's/^COMPRESSXZ.*/COMPRESSXZ=(xz -T "$(getconf _NPROCESSORS_ONLN)" -c -z --best -)/' /etc/makepkg.conf
sed -i 's/^COMPRESSZST.*/COMPRESSZST=(zstd -c -z -q --ultra -T0 -22 -)/' /etc/makepkg.conf
sed -i 's/^COMPRESSLZ.*/COMPRESSLZ=(lzip -c -f)/' /etc/makepkg.conf
sed -i 's/^COMPRESSLRZ.*/COMPRESSLRZ=(lrzip -9 -q)/' /etc/makepkg.conf
sed -i 's/^COMPRESSLZO.*/COMPRESSLZO=(lzop -q --best)/' /etc/makepkg.conf
sed -i 's/^COMPRESSZ.*/COMPRESSZ=(compress -c -f)/' /etc/makepkg.conf
sed -i 's/^COMPRESSLZ4.*/COMPRESSLZ4=(lz4 -q --best)/' /etc/makepkg.conf

# SAFETY
sed -i 's/^umask.*/umask\ 077/' /etc/profile
echo "auth optional pam_faildelay.so delay=4000000" >>/etc/pam.d/system-login
echo "tcp_bbr" >/etc/modules-load.d/bbr.conf
echo "write-cache" >/etc/apparmor/parser.conf

# Enable pam
cat <<EOF >/etc/pam.d/login
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start
EOF

cat <<EOF >/etc/pam.d/passwd
#%PAM-1.0

#password	required	pam_cracklib.so difok=2 minlen=8 dcredit=2 ocredit=2 retry=3
#password	required	pam_unix.so sha512 shadow use_authtok
password	required	pam_unix.so sha512 shadow nullok
password	optional	pam_gnome_keyring.so
EOF
