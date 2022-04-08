# vfio-pci-host-xorg-device
TODO:

  Needs peer-review. I need help with Bash syntax!

TL;DR:

  Script runs at boot, finds first VGA device with proper driver active and runs xorg from said device. See README.

Long version:

  Script runs at boot time, finds the first (host/hypervisor GPU) VGA PCI device without the kernel driver "vfio-pci" active, grabs the PCI ID, and writes the PCI ID and kernel driver to a xorg.conf file (EXAMPLE: "/etc/X11/xorg.conf.d/10-radeon.conf".

  All other files (recognized as "./10-kernel_driver.conf") are set to be NOT readable (or inaccessible by xorg). This way xorg will only boot the display manager from the first (preferred) GPU.

Why?:

  I use GRUB customizer to setup multiple boot options with my VM with VFIO Passthrough setup. Right now, VFIO works short of perfect. Without this script, I have to manually comment/uncomment "secondary-gpu.conf" to get to my display manager. :-)
