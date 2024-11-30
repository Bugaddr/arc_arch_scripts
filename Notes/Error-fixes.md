### Open ACPI failed

1. (/var/run/acpid.socket) (No such file or directory) in ~/.local/share/xorg.0.log

2. Not necessary can be fixed in xorg config [https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Listening_to_ACPI_events]

    ```bash
    pacman -S acpid
    systemctl enable acpid
    ```

### cfg80211: failed to load regulatory.db in dmesg

For legal purposes, not necessary

    ```bash
    pacman -S wireless-regdb
    iw reg set IN
    ```

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
```

### Virt-manager closes/crashes when waking from suspend

1. <https://github.com/virt-manager/virt-manager/issues/501>
2. <https://bugzilla.redhat.com/show_bug.cgi?id=2175667>
3. Patch is merged in upstream. Subsequent release of spice-gtk should fix this, till then enjoy the coredumps

### PC not suspending on 6.6.35-2-lts kernel

1. No specific cause known, use stable kernel instead of lts

### Captive portal not working

1. Check `/etc/dns-over-https/doh-client.conf` along with DoH.

### Iwlwifi coredump

1. Stop using problemetic firmware

    ```
    sudo mv iwlwifi-so-a0-hr-b0-83.ucode.zst iwlwifi-so-a0-hr-b0-83.ucode.zst.b
    ```
