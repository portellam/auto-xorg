## What is VFIO?
* see hyperlink:    https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* community:        https://old.reddit.com/r/VFIO
* a useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

#
## How-to
* In terminal, execute:
 
        sudo bash installer.sh
* It is NOT necessary to execute 'Auto-Xorg.sh'. The service will run once at boot. See '/etc/X11/xorg.conf.d/10-Auto-Xorg.conf'.
* Optionally, to restart the active Display Manager, execute:

        sudo bash Auto-Xorg.sh dm
  

#
## Auto-Xorg
Generates Xorg for first non-VFIO VGA device.
* Runs once at boot.
* Parses list of PCI devices:

        lspci -k
* Saves first (valid) available VGA device.
  * Valid example:

        04:00.0 VGA compatible controller: ...
        Kernel driver in use: nvidia
  * Invalid example:

        01:00.0 VGA compatible controller: ...
        Kernel driver in use: vfio-pci
* Appends to Xorg file ('/etc/X11/xorg.conf.d/10-Xorg-vfio-pci.conf').
* Optionally, restart active display manager (you may modify 'Auto-Xorg.service' to do this automatically).

        sudo bash Auto-Xorg.sh dm

#
## Why?
In my experience, swapping host graphics is trivial and tedious. Either by changing config files or 'Multi-Booting' (see **https://github.com/portellam/Auto-VFIO/**), updating Xorg is necessary to boot properly.

I don't believe the Linux team or VFIO community has made a simple script for this purpose already. In response, I made this simple script, and enjoyed the time spent.

I understand the majority of the VFIO community is part of the greater Linux community, which itself is small relative to the world. They will understand this, I spent too long with VFIO setups before. This too lol
