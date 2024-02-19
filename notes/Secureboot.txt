# ENable secure boot

1. pacman -S --needed sbctl
2. Create keys
`sbctl create-keys`
3. Enter UEFI setup and change secure boot mode to custom
`systemctl reboot --firmware-setup`
4. Enroll with Microsoft keys
`sbctl enroll-keys -m`
5. sbctl verify | sed 's/✗ /sbctl sign -s \//e'

