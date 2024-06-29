#!/usr/bin/env bash

# Remove useless pkg
pacman -Rcnsd rsh-server telnet-server

# Debloat xorg
pacman -Qqge xorg | grep -vxe xorg-server -e xorg-mkfontscale -e xorg-font-util - | sudo pacman -Rnsd
pacman -Rcnsd xorg-fonts-75dpi xorg-fonts-100dpi xorg-docs

# Delete old/temp files
fd -g *.old -x rm -rifv
fd -g *.tmp -x rm -rifv
fd -t e -x rm -rifv

# Remove more unneeded packages
pacman -Qtdq | pacman -Rns -
pacman -Qqd | pacman -Rsu -

# Delete pacman db/pkg cache
pacman -Sc
pacman -Scc

# TODO: Lostfiles

# Journal
journalctl --rotate --vacuum-time=1s --vacuum-size=0B

# Delete home cache folder
rm -rfv ~/.cache/*
