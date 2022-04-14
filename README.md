# vfio-xorg-vga
TL;DR:

  Script runs at boot, finds first VGA device with proper driver active and runs xorg from said device. See README.

Long version:

  Script runs at boot time, finds the first (host/hypervisor GPU) VGA PCI device without the kernel driver "vfio-pci" active, grabs the PCI ID, and writes the PCI ID and kernel driver to a xorg.conf file (EXAMPLE: "/etc/X11/xorg.conf.d/10-'driver'.conf").

  All driver xorg files "10-'driver'.conf" will be deleted at start. I have been unsuccessful setting file permissions to prevent read at boot time.

Why?

  I use GRUB customizer to setup multiple boot options with my VM with VFIO Passthrough setup. Right now, VFIO works short of perfect. Without this script, I have to manually comment/uncomment "secondary-gpu.conf" to get to my display manager. :-)
