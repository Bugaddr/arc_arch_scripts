#!/usr/bin/env bash

# Install redshift
pacman -S --needed redshift python-gobject python-xdg

# Location
LAT="$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | awk 'OFS=":" {print $3,$5}' | tr -d ',}' | cut -d':' -f1)"
LON="$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | awk 'OFS=":" {print $3,$5}' | tr -d ',}' | cut -d':' -f2)"

# Redshift config [Gradually after few month change to 3500]
mkdir -pv /home/"$USER"/.config/redshift/
echo -e "[redshift]
temp-day=6500
temp-night=3800
gamma-day=0.8:0.7:0.8
gamma-night=0.6
adjustment-method=randr
location-provider=manual

[manual]
lat=$LAT
lon=$LON" >/home/"$USER"/.config/redshift/redshift.conf

# Enable redshift with systemd
systemctl --user enable --now redshift-gtk
systemctl --user start --now redshift-gtk

# Cleanup
unset LAT
unset LON
