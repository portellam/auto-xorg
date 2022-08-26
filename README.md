## Description
Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.

## How-to
* To install, execute:

        sudo bash installer.bash
* To run stand-alone, execute: (add/remove input variable **'y'** to find first/last video device)

        sudo bash auto-xorg.bash y

## What is VFIO?
* see hyperlink:    https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* community:        https://old.reddit.com/r/VFIO
* a useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Auto-Xorg
* Runs once at boot.
* Parses list of PCI devices:

        lspci -k
* Saves valid and available VGA device.
  * Valid example:

        04:00.0 VGA compatible controller: ...
        Kernel driver in use: nvidia
  * Invalid example:

        01:00.0 VGA compatible controller: ...
        Kernel driver in use: vfio-pci
* Appends to Xorg file (**'/etc/X11/xorg.conf.d/10-auto-xorg.conf'**).

## Why?
Swapping the host/boot video device (VGA) is trivial and tedious.

For whatever the reason, this script has you covered:
* a fresh VFIO setup
* switching the boot VGA (**https://github.com/portellam/deploy-VFIO-setup/**)
* deploying multiple setups

Note, I don't believe the Linux team or VFIO community has made a script for a purpose like this before. In response, I made this script and enjoyed learning something new!