# Open ACPI failed (/var/run/acpid.socket) (No such file or directory) in ~/.local/share/xorg.0.log
# Not necessary can be fixed in xorg config [https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Listening_to_ACPI_events]
pacman -S acpid
systemctl enable acpid

# cfg80211: failed to load regulatory.db in dmesg
# For legal purposes, not necessary
pacman -S wireless-regdb
iw reg set IN

# NO sound
pacman -S pipewire
pacman -S pipewire-pulse # Pulseaudio support
pacman -S pipewire-alsa  # Alsa support
pacman -S pipewire-jack  # Jack support
pacman -S wireplumber    # Media session handeler

systemctl --user enable --now pipewire.socket
systemctl --user enable --now pipewire-pulse.socket
systemctl --user enable --now wireplumber.service

# pipewire[1181]: mod.rt: Can't find xdg-portal: (null)
pacman -S xdg-desktop-portal # Desktop integration portals for sandboxed apps [Also need backend eg. xdg-desktop-portal-kde]

# Fix ldconfig "file is empty, not checked" error 
# https://gist.github.com/metzenseifner/cb61ecfd614a93c5927ba3cd62d68127
# Forcefully reinstall everything otherwise you might get "exists in filesystem" errors in chroot
pacman -Syyu $(pacman -Qnq) --overwrite '*'

# Qemu No internet
# Try above, and check the firewall (its always mf firewall)
ufw disable
ufw reset
ufw default deny incoming
ufw default allow outgoing
ufw enable

# virt-manager closes/crashes when waking from suspend
# https://github.com/virt-manager/virt-manager/issues/501
# https://bugzilla.redhat.com/show_bug.cgi?id=2175667
# https://gitlab.freedesktop.org/spice/spice-gtk/-/merge_requests/125
Patch merged in upstream. Subsequent release of spice-gtk should fix this, till then enjoy the coredumps
