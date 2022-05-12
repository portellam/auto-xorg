## What is VFIO?
* See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
* Community:      https://old.reddit.com/r/VFIO
#

## How-to
* In terminal, execute 'sudo bash installer.sh'
  * It is NOT necessary to run 'Auto-Xorg'. The service will run once at boot. See '/etc/X11/xorg.conf.d/10-Auto-Xorg.conf'.

## Auto-Xorg
**TL;DR:** Generates Xorg for first available VGA device.
#### Long version;
Run Once at boot. Parses list of PCI devices, saves first VGA device (without vfio-pci driver). Appends to Xorg file ('/etc/X11/xorg.conf.d/10-Xorg-vfio-pci.conf').
#

## Why?
If you setup VFIO Passthrough statically or dynamically (Multi-Boot), this script will automate the process of Xorg finding a valid VGA device.
* Valid VGA device example:
  * *01:00.0 VGA compatible controller: ...
        *Kernel driver in use: **nvidia***
* Invalid VGA device example:
  * *01:00.0 VGA compatible controller: ...
        Kernel driver in use: **vfio-pci** *
