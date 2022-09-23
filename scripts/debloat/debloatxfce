#!/usr/bin/env bash

# Remove Xfce junk
pacman -Rcnsd xfce4-terminal xfce4-appfinder tumbler

# Junk Themes
JUNKTHEME=(
	Adept
	Agua
	Agualemon
	Alternate
	Atlanta
	Atlanta2
	B5
	B6
	Basix
	BBS
	Beastie
	Biz
	Blackwall
	#Bright # Needed by libnotify
	Buzz
	Clearlooks
	Coldsteel
	Coolclean
	Crux
	Cruxish
	Curve
	Daloa
	#Default # Default theme
	Default-4.0
	Default-4.2
	Default-4.4
	Default-4.6
	Default-4.8
	Default-hdpi
	Default-xhdpi
	Defcon-IV
	Eazel-blue
	Elberg
	Emacs
	Exocet
	Fbx
	G2
	Galaxy
	Gaudy
	Gelly
	Gnububble
	Gorilla
	Gtk
	Iceg
	Industrial
	Kde
	Kde1
	Keramik
	Kindaker
	Kleanux
	Kokodi
	Koynacity
	Linea
	LineArt
	Meenee
	Metabox
	Microcurve
	Microdeck
	Microdeck2
	Microdeck3
	Microgui
	Mist
	Mofit
	Moheli
	Next
	Ops
	Opta
	Oroborus
	Perl
	Pills
	Piranha
	Platinum
	Prune
	Quiet-purple
	Quinx
	R9X
	Raleigh
	Redmond
	RedmondXP
	Retro
	Sassandra
	Silverado
	Slick
	Slimline
	Smallscreen
	Smoke
	Smoothwall
	Stoneage
	Symphony
	Synthetic
	Tabs
	Tgc
	Tgc-large
	Therapy
	ThinIce
	Today
	Totem
	Trench
	Triviality
	Tubular
	TUX
	Tyrex
	Variation
	Wallis
	Waza
	Wildbush
	Xfce
	'ZOMG-PONIES!'
)

# Debloat themes now
for A in "${JUNKTHEME[@]}"; do
	rm -rvf "/usr/share/themes/$A"
done
