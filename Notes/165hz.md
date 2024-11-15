# Enable 165Hz with edid mod

1. Add the edid loader script

    ```bash
    cat <<'EOF' >/etc/initcpio/install/edid
    # !/bin/bash
    build() {
        add_file /lib/firmware/edid/edid.bin
    }
    EOF
    ```

2. `chmod a+x /etc/initcpio/install/edid`
3. `mkdir -p /lib/firmware/edid && cp ./edid.bin /lib/firmware/edid/edid.bin`
4. `sed -i 's|$| drm.edid_firmware=eDP-1:edid/edid.bin|' /etc/kernel/cmdline`
5. Add edid to mkinitcpio HOOKS in /etc/mkinitcpio.conf

    ```text
    HOOKS=(base systemd autodetect keyboard keymap modconf block sd-encrypt filesystems fsck edid)
    ```

6. `mkinitcpio -P`

## Switch bw 165/144/60 with cli

1. <https://www.reddit.com/r/kde/comments/1d1urtx/comment/lbpxa2v/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button>
2. `kscreen-doctor output.eDP-1.mode.2560x1440@165` for 165
3. `kscreen-doctor output.eDP-1.mode.2560x1440@144` for 144
4. `kscreen-doctor -o` to check
