## Description
Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.

## How-to
#### To install, execute:
        sudo bash installer.bash

#### To run stand-alone, execute:
        sudo bash auto-xorg.bash

#### Usage
        -f, --first             find the first valid VGA device
        -h, --help              Print this usage statement
        -l, --last              find the last valid VGA device
        -r, --restart-display   restart the display manager immediately

        Prefer a vendor:

        -a, --amd               AMD or ATI
        -i, --intel             Intel
        -n, --nvidia            NVIDIA
        -o, --other             any other brand (past or future)

#### Examples
        bash auto-xorg -f -a    Find first valid AMD/ATI VGA device.
        bash auto-xorg -l -n -r Find last valid NVIDIA VGA device, then restart the display manager immediately.

#### If the Auto-Xorg service fails, to diagnose review the log. Execute:
        sudo journalctl -u auto-xorg

Failure may mean an absent VGA device, or an exception. Review the log to debug.

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
Tested on Debian Linux, on my personal Laptop PC (Thinkpad T500-series, with NVIDIA Optimus) and Desktop PC (Intel Core 9th Gen. and Z390 motherboard).

My Desktop has no issues and works as expected. Primary and secondary GPUs are NVIDIA 10-series and AMD Radeon HD 6900-series, respectively. Given such a setup, I am able to successfully alternate between Windows 10 and Windows XP virtual machines.

**I daily drive this Desktop, and Auto-Xorg works as expected.** Whenever I choose to boot either VGA device, it does the job.

However my Laptop has some issues:
* **lspci** parses Intel VGA driver **"i915"** (which is blacklisted and superseded by **"modesetting**"). This driver mis-match causes Auto-Xorg to write an invalid Xorg configuration file.
* the laptop does not support VGA passthrough at all. For this use-case, Auto-Xorg will provide zero benefit.

## To-do
In the future, I would like to create a specific, distro-independent function. The function will check for if the more recent Intel driver (**"modesetting"**) is present or not, and apply an Xorg file accordingly.