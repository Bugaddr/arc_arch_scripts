### Open ACPI failed

1. (/var/run/acpid.socket) (No such file or directory) in ~/.local/share/xorg.0.log

2. Not necessary can be fixed in xorg config [https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Listening_to_ACPI_events]

   ```bash
   pacman -S acpid
   systemctl enable acpid
   ```

### cfg80211: failed to load regulatory.db in dmesg

For legal purposes, not necessary

    pacman -S wireless-regdb
    iw reg set IN

### No sound

```bash
pacman -S pipewire
pacman -S pipewire-pulse # Pulseaudio support
pacman -S pipewire-alsa  # Alsa support
pacman -S pipewire-jack  # Jack support
pacman -S wireplumber    # Media session handeler

systemctl --user enable --now pipewire.socket
systemctl --user enable --now pipewire-pulse.socket
systemctl --user enable --now wireplumber.service
```

### pipewire[1181]: mod.rt: Can't find xdg-portal: (null)

Desktop integration portals for sandboxed apps [Also need backend eg. xdg-desktop-portal-kde]

```bash
pacman -S xdg-desktop-portal
```

### Fix ldconfig "file is empty, not checked" error

1. <https://gist.github.com/metzenseifner/cb61ecfd614a93c5927ba3cd62d68127>
2. Forcefully reinstall everything otherwise you might get "exists in filesystem" errors in chroot.

   ```bash
   pacman -Syyu $(pacman -Qnq) --overwrite '*'
   ```

### Qemu No internet

Try above, and check the firewall (its always mf firewall)

```bash
ufw disable
ufw reset
ufw default deny incoming
ufw default allow outgoing
ufw enable
ufw allow in on virbr0 from any to any
ufw reload
```

### Virt-manager closes/crashes when waking from suspend

1. <https://github.com/virt-manager/virt-manager/issues/501>
2. <https://bugzilla.redhat.com/show_bug.cgi?id=2175667>
3. Patch is merged in upstream. Subsequent release of spice-gtk should fix this, till then enjoy the coredumps
4. Should be fixed with spice-gtk V0.42-4

### PC not suspending on 6.6.35-2-lts kernel

1. No specific cause known, use stable kernel instead of lts

### Captive portal not working

1. Check `/etc/dns-over-https/doh-client.conf` along with DoH.

### Iwlwifi coredump

1. Stop using problemetic firmware

   ```
   sudo mv iwlwifi-so-a0-hr-b0-83.ucode.zst iwlwifi-so-a0-hr-b0-83.ucode.zst.b
   ```

### Stop discover from autostarting

1. <https://www.reddit.com/r/kde/comments/f2bquo/how_to_stop_discover_from_autostarting/>
2. `mv /etc/xdg/autostart/org.kde.discover.notifier.desktop /etc/xdg/autostart/org.kde.discover.notifier.desktop.bak`
3. `echo 'NoExtract = etc/xdg/autostart/org.kde.discover.notifier.desktop' >> /etc/pacman.conf`

### Touchpad slowing fix

1. make the following file: `/etc/libinput/local-overrides.quirks`

   ```
   [Touchpad Correction]
   MatchUdevType=touchpad
   MatchName=*ELAN050A*
   AttrSizeHint=90x50
   ```

   or

2. add the following in `/etc/udev/rules.d/99-touchpad-power.rules`

   ```
   ACTION=="add", SUBSYSTEM=="i2c", ATTR{name}=="ELAN050A:01", TEST=="power/control", ATTR{power/control}="on"
   ```

   then reload with:

   ```
   sudo udevadm control --reload-rules && sudo udevadm trigger
   ```

   or

3. Add `i2c_hid.disable_power_management=1` to kernel cmdline

### Automatic dark mode switching

1. Install pkgs

```bash
pacman -S xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-desktop-portal darkman
```

2. Use config from dotfiles & enable services

```bash
systemctl --user enable darkman
```

### Creating consistent device paths for specific gpu cards

1. Create intel igpu

```bash
SYMLINK_NAME="intel-igpu"
RULE_PATH="/etc/udev/rules.d/intel-igpu-dev-path.rules"
INTEL_IGPU_ID="0000:00:02.0"
UDEV_RULE="$(cat <<EOF
KERNEL=="card*", \
KERNELS=="$INTEL_IGPU_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/$SYMLINK_NAME"
EOF
)"

echo "$UDEV_RULE" | sudo tee "$RULE_PATH"
```

2. Create nvidia dgpu path

```bash
SYMLINK_NAME="nvidia-dgpu"
RULE_PATH="/etc/udev/rules.d/nvidia-dgpu-dev-path.rules"
NVIDIA_GPU_ID="0000:01:00.0"
UDEV_RULE="$(cat <<EOF
KERNEL=="card*", \
KERNELS=="$NVIDIA_GPU_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/$SYMLINK_NAME"
EOF
)"

echo "$UDEV_RULE" | sudo tee "$RULE_PATH"
```

3. Apply

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```
### Fix arduino ide permission denied

1. Create this file
   ```bash
   sudo tee /etc/udev/rules.d/50-arduino.rules > /dev/null << 'EOF'
   SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", GROUP="uucp", MODE="0666"
   SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", GROUP="uucp", MODE="0666"
   EOF
   ```
2. Apply
   ```bash
   sudo udevadm control --reload-rules && sudo udevadm trigger
   ```
