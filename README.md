## What is VFIO?
* See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
* Community:      https://old.reddit.com/r/VFIO
#

#

## How-to
* In terminal, execute 'sudo bash installer.sh'
  * It is NOT necessary to run 'Auto-Xorg'. The service will run once at boot. See '/etc/X11/xorg.conf.d/10-Auto-Xorg.conf'.
#

## Auto-Xorg
Generates Xorg for first found available VGA device.
* Runs once at boot.
* Parses list of PCI devices, saves first (valid) available VGA device. **[1]**
* Appends to Xorg file ('/etc/X11/xorg.conf.d/10-Xorg-vfio-pci.conf').
* Optionally, restart active display manager ('sudo bash Auto-Xorg.sh dm').

**[1]**
* Valid VGA device example:

        04:00.0 VGA compatible controller: ...
        Kernel driver in use: nvidia
* Invalid VGA device example:

        01:00.0 VGA compatible controller: ...
        Kernel driver in use: vfio-pci  
