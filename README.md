## Status: Work-in-progress
# Xorg-vfio-pci
TL;DR:

  Runs at boot. Finds first **VGA device without vfio-pci** kernel driver. Creates an Xorg file (example: "/etc/X11/xorg.conf.d/10-nvidia-pci1_0_0.conf") with the VGA device's **PCI bus ID** and **PCI kernel driver**. Prior to creation of the Xorg file, all other files with the same filename ("/etc/X11/xorg.conf.d/10-**kernel_driver**.conf") will be deleted.

Why?

  **I want to use this.** My goal is to use multiple GRUB boot options with custom command-lines (including vfio-pci), of each device to passthrough. Each GRUB boot option will have a **different VGA device that is NOT grabbed by vfio-pci**. Does this make sense?
  
TO-DO:
* test!
* allow script to run at boot, example: Systemd service
