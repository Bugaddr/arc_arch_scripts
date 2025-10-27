#!/usr/bin/env bash

# Setup hyprpolkit agent
pacman -S hyprpolkitagent
systemctl --user enable --now hyprpolkitagent.service
