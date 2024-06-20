# Auto X.Org
### v1.1.1
Automatically set the proper video output given a video device (VGA) is
unavailable due to hardware-passthrough (VFIO) or any other reason, in the X.Org
display environment for a Linux machine.

**Download the Latest Release:**&ensp;[Codeberg][codeberg-releases],
[GitHub][github-releases]

[codeberg-releases]: https://codeberg.org/portellam/auto-xorg/releases/latest
[github-releases]:   https://github.com/portellam/auto-xorg/releases/latest

## Table of Contents
- [Why?](#why)
- [Related Projects](#related-projects)
- [Documentation](#documentation)
- [Download](#download)
- [Host Requirements](#host-requirements)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Contact](#contact)
- [References](#references)

## Contents
### Why?
X.Org will specify a VGA device to be the primary video output. When that VGA
device is *Passed-through* or restricted to Virtual Machines (VMs) only (like in
a VFIO setup), the VGA device cannot be used by the Host machine (Linux).
Unfortunately, X.Org will not search for the next valid VGA device. *This is*
*where auto-X.Org steps in...*

This script will automatically set the proper video output everytime, as it runs
at Host startup. This flexibility is very useful for a new or changing VFIO
setup.

### Related Projects
| Project                             | Codeberg          | GitHub          |
| :---                                | :---:             | :---:           |
| Deploy VFIO                         | [link][codeberg1] | [link][github1] |
| **Auto X.Org**                      | [link][codeberg2] | [link][github2] |
| Generate Evdev                      | [link][codeberg3] | [link][github3] |
| Guest Machine Guide                 | [link][codeberg4] | [link][github4] |
| Libvirt Hooks                       | [link][codeberg5] | [link][github5] |
| Power State Virtual Machine Manager | [link][codeberg6] | [link][github6] |

[codeberg1]: https://codeberg.org/portellam/deploy-VFIO
[github1]:   https://github.com/portellam/deploy-VFIO
[codeberg2]: https://codeberg.org/portellam/auto-xorg
[github2]:   https://github.com/portellam/auto-xorg
[codeberg3]: https://codeberg.org/portellam/generate-evdev
[github3]:   https://github.com/portellam/generate-evdev
[codeberg4]: https://codeberg.org/portellam/guest-machine-guide
[github4]:   https://github.com/portellam/guest-machine-guide
[codeberg5]: https://codeberg.org/portellam/libvirt-hooks
[github5]:   https://github.com/portellam/libvirt-hooks
[codeberg6]: https://codeberg.org/portellam/powerstate-virtmanager
[github6]:   https://github.com/portellam/powerstate-virtmanager

### Documentation
- [What is VFIO?](#2)
- [VFIO Discussion and Support](#3)
- [Hardware-Passthrough Guide](#1)
- [Virtual Machine XML Format Guide](#4)

### Download
- To download this script, you may:
  - Download the Latest Release:&ensp;[Codeberg][codeberg-releases],
[GitHub][github-releases]

  - Download the ZIP file:
    1. Viewing from the top of the repository's (current) webpage, click the
       drop-down icon:
      - `···` on Codeberg.
      - `<> Code ` on GitHub.

    2. Click `Download ZIP`. Save this file.

    3. Open the `.zip` file, then extract its contents.

  - Clone the repository:
    1. Open a Command Line Interface (CLI).
      - Open a console emulator (for Debian systems: Konsole).

      - Open a existing console: press `CTRL` + `ALT` + `F2`, `F3`, `F4`, `F5`,
      or `F6`.
        - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
        - `F1` is reserved for debug output of the Linux kernel.
        - `F7` is reserved for video output of the desktop environment.
        - `F8` and above are unused.

    2. Change your directory to your home folder or anywhere safe: `cd ~`

    3. Clone the repository:
      - `git clone https://www.codeberg.org/portellam/auto-xorg`
      - `git clone https://www.github.com/portellam/auto-xorg`

- To make this script executable, you must:
  1. Open the CLI (see above).

  2. Go to the directory of where the cloned/extracted repository folder is: `cd name_of_parent_folder/auto-xorg/`

  3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will
    perform this action.
    - Do **not** make any non-script file executable. This is not necessary and
    potentially dangerous.

### Host Requirements
- `systemd` for system services.
- `X.Org` or `X11` as the video display environment.
- `Wayland` is not supported.
  - Wayland causes problems for NVIDIA devices.
  - In general, it is [a buggy mess] not ready for production.

[a buggy mess]: https://web.archive.org/web/20240306152042/https://gist.github.com/probonopd/9feb7c20257af5dd915e3a9f2d1f2277

### Usage
#### 1. `installer.bash` or `auto-xorg`
- From within the project folder, execute: `sudo bash installer.bash`
- Or after installation, from any folder execute: `sudo bash auto-xorg`
  - The CLI's shell (bash) should recognize that the script file is located in
  `/usr/local/bin`.
```
  -h, --help              Print this help and exit.

Update X.Org:
  -r, --restart-display   Restart the display manager immediately.

Set device order:
  -f, --first             Find the first valid VGA device.
  -l, --last              Find the last valid VGA device.

Prefer a vendor:
  -a, --amd               AMD or ATI
  -i, --intel             Intel
  -n, --nvidia            NVIDIA
  -o, --other             Any other brand (past or future).
```

#### 2. Usage Examples
- Set options to find first valid AMD/ATI VGA device, then install:
```
sudo bash auto-xorg.bash -f -a
```

- Find last valid NVIDIA VGA device, then restart the display manager
immediately:
```
sudo bash auto-xorg -l -n -r
```

#### 3. Troubleshooting
If the auto-xorg service fails, to diagnose review the log, execute:
```
sudo journalctl -u auto-xorg
```

Failure may be the result of absent VGA device(s), or an exception. Review the
log to debug.

### How It Works
- Runs once at boot.
- Parses list of VGA devices:
```
lspci -m | grep --extended-regexp --ignore-case 'vga|graphics'
```

- Saves valid and available VGA device:
```
  lspci -ks 04:00.0 | grep --extended-regexp --ignore-case 'driver|VGA'

  04:00.0 VGA compatible controller: ...
  Kernel driver in use: nvidia
```

- Invalid example:
```
  lspci -ks 04:00.0 | grep --extended-regexp --ignore-case 'driver|VGA'

  01:00.0 VGA compatible controller: ...
  Kernel driver in use: vfio-pci
```

- Appends to X.Org file: `/etc/X11/xorg.conf.d/10-auto-xorg.conf`

### Contact
Did you encounter a bug? Do you need help? Please visit the
**Issues page** ([Codeberg][codeberg-issues], [GitHub][github-issues]).

[codeberg-issues]: https://codeberg.org/portellam/auto-xorg/issues
[github-issues]:   https://github.com/portellam/auto-xorg/issues

### References
#### 1.
**PCI passthrough via OVMF**. ArchWiki. Accessed June 14, 2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 2.
**VFIO - ‘Virtual Function I/O’ - The Linux Kernel Documentation**.
The linux kernel. Accessed June 14, 2024.
<sup>https://www.kernel.org/doc/html/latest/driver-api/vfio.html.</sup>

#### 3.
**VFIO Discussion and Support**. Reddit. Accessed June 14, 2024.
<sup>https://www.reddit.com/r/VFIO/.</sup>

#### 4.
**libvirt/libvirt - XML Design Format** GitHub. Accessed June 18, 2024.
<sup>https://github.com/libvirt/libvirt/blob/master/docs/formatdomain.rst.</sup>