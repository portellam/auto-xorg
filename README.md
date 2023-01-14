## Description
Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.

## How-to
#### To install, execute:
        sudo bash installer.bash
#### To run stand-alone, execute:
        sudo bash auto-xorg.bash y
Add input variable to find first or last VGA device. **[Y/n]** You may omit input to prefer the latter.

## What is VFIO?
* see hyperlink:    https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* community:        https://old.reddit.com/r/VFIO
* a useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Auto-Xorg
* Runs once at boot.
* Parses list of VGA devices:

        lspci -m | grep -Ei 'vga|graphics'
* Saves valid and available VGA device:

        lspci -ks 04:00.0 | grep -Ei 'driver|VGA'

        04:00.0 VGA compatible controller: ...
        Kernel driver in use: nvidia
* Invalid example:

        lspci -ks 04:00.0 | grep -Ei 'driver|VGA'

        01:00.0 VGA compatible controller: ...
        Kernel driver in use: vfio-pci

* Appends to Xorg file (**'/etc/X11/xorg.conf.d/10-auto-xorg.conf'**).

## Why?
Swapping the host/boot video device (VGA) is trivial and tedious.

For whatever the reason, this script has you covered:
* a fresh VFIO setup
* switching the boot VGA (**https://github.com/portellam/deploy-VFIO-setup/**)
* deploying multiple setups

As of when I started this project, I fail to find another similar script such as this.
I am proud for this to be my first foray into Bash programming.
I am happy to share this with the VFIO community.

## Disclaimer
Tested on Debian Linux, on my personal laptop PC (Thinkpad T500-series, with NVIDIA Optimus) and desktop PC (Intel Core 9th Gen. and Z390 motherboard).

My desktop has no issues and works as expected. Primary and secondary GPUs are NVIDIA 10-series and AMD Radeon HD 6900-series, respectively.
**I daily drive this Desktop, and Auto-Xorg works as expected. It such a help for whenever I choose boot either VGA device.**

However my laptop has some issues:

* **lspci** parses Intel VGA driver **"i915"** (which is blacklisted and superseded by **"modesetting**"). This driver mis-match causes Auto-Xorg to write an invalid Xorg configuration file.
* the laptop does not support VGA passthrough at all. For this use-case, Auto-Xorg will provide zero benefit.

## To-do
In the future, I would like to create a specific, distro-independent function. The function will check for if the more recent Intel driver (**"modesetting"**) is present or not, and apply an Xorg file accordingly.