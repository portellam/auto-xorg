# WIP
# vfio-xorg-vga
TL;DR:

  Script runs at boot, finds first VGA device with proper driver active and runs xorg from said device. See README.

Why?

  I use GRUB customizer to setup multiple boot options with my VM with VFIO Passthrough setup. Right now, VFIO works short of perfect. Without this script, I have to manually comment/uncomment "secondary-gpu.conf" to get to my display manager. :-)
