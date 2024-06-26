# Auto decrypt root with TPM

## Use systemd boot
1. Add systemd after udev and before autodetect instead in /etc/mkinitcpio.conf
2. Ensure sd-encrypt after block and before filesystems instead of encrypt in /etc/mkinitcpio.conf
E.g: HOOKS=(base systemd autodetect keyboard keymap modconf block sd-encrypt filesystems fsck edid)
3. mkinitcpio -p linux-lts

## Add password to TPM
1. systemd-cryptenroll --recovery-key /dev/nvme0n1p6
2. systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p6
