# ENable secure boot

1. Install sbctl

    ```bash
    pacman -S --needed sbctl
    ```

2. Create keys

    ```bash
    sbctl create-keys
    ```

3. Enter UEFI setup and change secure boot mode to custom (Clear all other keys, dont factory reset)

    ```bash
    systemctl reboot --firmware-setup
    ```

4. Enroll with Microsoft keys

    ```bash
    sbctl enroll-keys -m
    ```

5. Sign unsigned binaries !!

    ```bash
    sbctl verify | sed 's/✗ /sbctl sign -s \//e'
    ```
