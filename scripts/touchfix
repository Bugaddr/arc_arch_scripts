#!/bin/bash

sudo modprobe -r psmouse
sudo modprobe psmouse synaptics_intertouch=0 proto=exps
echo "Attempt 1"
read

sudo modprobe -r psmouse
sudo modprobe psmouse synaptics_intertouch=0
echo "Attempt 2"
read

sudo modprobe -r psmouse
sudo modprobe psmouse synaptics_intertouch=1 proto=exps
echo "Attempt 3"
read

sudo modprobe -r psmouse
sudo modprobe psmouse synaptics_intertouch=1
echo "Attempt 4"
read

# IF ANY SUCESSFUL add 'options psmouse synaptics_intertouch=1' to /etc/modprobe.d/psmouse.conf
# THEN sudo modprobe -r psmouse && sudo modprobe psmouse
#https://www.reddit.com/r/linuxmint/comments/ayjkj4/thinkpad_touchpad_not_working_on_latest_kernels/
# ALSO cmdline:  psmouse.synaptics_intertouch=1 psmouse.proto=exps
# https://askubuntu.com/questions/1235067/touchpad-stopped-working-20-04
