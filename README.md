## Description
Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.

## How-to
* To install, execute:

        sudo bash installer.bash
* To run stand-alone, execute: (add input variable **'y'** or **'n'** (or none) to find first or last VGA device)

        sudo bash auto-xorg.bash y

## What is VFIO?
* see hyperlink:    https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* community:        https://old.reddit.com/r/VFIO
* a useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Auto-Xorg
* Runs once at boot.
* Parses list of PCI devices:

        lspci -m | grep -Ev "VGA|Graphics"
* Saves valid and available VGA device.
  * Valid example:

        *04:00.0 VGA compatible controller: ...*

        lspci -ks 04:00.0 | grep driver | cut -d ':' -f2 | cut -d ' ' -f2
        *Kernel driver in use: nvidia*
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

## DISCLAIMER
Tested on Debian Linux, personal laptop (Thinkpad T500-series, with NVIDIA Optimus) and desktop (Intel Core 9th Gen. and Z390 motherboard).

Given desktop (active GPUs are NVIDIA and AMD) has no issues and works as expected. however laptop has some.
On given Laptop, the lspci parses Intel VGA driver "i915" (which is blacklisted and superseded by "modesetting"). This driver mis-match causes Auto-Xorg to write an invalid Xorg configuration file.

In the future, I would like to create a specific, disro-independent function to check if the more recent ("modesetting") driver is present, and use that. In the meantime, keep this in mind.