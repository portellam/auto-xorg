# Auto X.Org
### v1.1.2
Automatically set the proper video output given a video device (VGA) is
unavailable due to hardware-passthrough (VFIO) or any other reason, in the X.Org
display environment for a Linux machine.

## [Download](#5-download)

## Table of Contents
- [1. Why?](#1-why)
- [2. Related Projects](#2-related-projects)
- [3. Documentation](#3-documentation)
- [4. Host Requirements](#4-host-requirements)
    - [4.1. Operating System](#41-operating-system)
    - [4.2. Software](#42-software)
    - [4.3. Hardware](#43-hardware)
- [5. Download](#5-download)
- [6. Usage](#6-usage)
    - [6.1. Verify Installer is Executable](#61-verify-script-is-executable)
    - [6.2. `installer.bash` or `auto-xorg`](#62-installerbash-or-auto-xorg)
    - [6.3. Examples](#63-examples)
    - [6.4. Troubleshooting](#64-troubleshooting)
- [7. How *Auto X.Org* Works](#7-how-auto-xorg-works)
- [8. Filenames and Pathnames Modified by Generate Evdev](#8-filenames-and-pathnames-modified-by-auto-xorg)
    - [8.1. System Files](#81-system-files)
    - [8.2. Binaries and Files](#82-binaries-and-files)
- [9. Contact](#9-contact)
- [10. References](#10-references)

## Contents
### 1. Why?
X.Org will specify a VGA device to be the primary video output. When that VGA
device is *Passed-through* or restricted to Virtual Machines (VMs) only (like in
a VFIO setup), the VGA device cannot be used by the Host machine (Linux).
Unfortunately, X.Org will not search for the next valid VGA device. **This is**
**where *Auto X.Org* steps in...**

This script will automatically set the proper video output everytime, as it runs
at Host startup. This flexibility is very useful for a new or changing VFIO
setup.

### 2. Related Projects
To view other relevant projects, visit [Codeberg][21]
or [GitHub][22].

[21]: https://codeberg.org/portellam/vfio-collection
[22]: https://github.com/portellam/vfio-collection

### 3. Documentation
- What is VFIO?[<sup>[2]</sup>](#2)
- VFIO Discussion and Support[<sup>[3]</sup>](#3)
- Hardware-Passthrough Guide[<sup>[1]</sup>](#1)
- Virtual Machine XML Format Guide[<sup>[4]</sup>](#4)

### 4. Host Requirements
#### 4.1. Operating System
Linux.

#### 4.2. Software
- `systemd` for system services.
- `X.Org` or `X11` as the video display environment.
- `Wayland` is not supported.
    - Wayland causes problems for NVIDIA devices (as of 2024).

#### 4.3. Hardware
Two (2) or more video devices. This script is not necessary for machines with
one video device, as X.Org will find it.

### 5. Download
- Download the Latest Release:&ensp;[Codeberg][51],
[GitHub][52]

- Download the `.zip` file:
    1. Viewing from the top of the repository's (current) webpage, click the
        drop-down icon:
        - `···` on Codeberg.
        - `<> Code ` on GitHub.
    2. Click `Download ZIP` and save.
    3. Open the `.zip` file, then extract its contents.

- Clone the repository:
    1. Open a Command Line Interface (CLI).
        - Open a console emulator (for Debian systems: Konsole).
        - Open an existing console: press `CTRL` + `ALT` + `F2`, `F3`, `F4`, `F5`,  or
        `F6`.
            - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
            - `F1` is reserved for debug output of the Linux kernel.
            - `F7` is reserved for video output of the desktop environment.
            - `F8` and above are unused.
    2. Change your directory to your home folder or anywhere safe:
        - `cd ~`
    3. Clone the repository:
        - `git clone https://www.codeberg.org/portellam/auto-xorg`
        - `git clone https://www.github.com/portellam/auto-xorg`

[51]: https://codeberg.org/portellam/auto-xorg/releases/latest
[52]: https://github.com/portellam/auto-xorg/releases/latest

### 6. Usage
#### 6.1. Verify Installer is Executable
1. Open the CLI (see [Download](#5-download)).

2. Go to the directory of where the cloned/extracted repository folder is:
`cd name_of_parent_folder/auto-xorg/`

3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will perform
  this action.
    - Do **not** make any non-script file executable. This is not necessary and
  potentially dangerous.

#### 6.2. `installer.bash` or `auto-xorg`
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

#### 6.3. Examples
- Set options to find first valid AMD/ATI VGA device, then install:
```
sudo bash installer.bash -f -a
```

- Find last valid NVIDIA VGA device, then restart the display manager
immediately:
```
sudo bash auto-xorg -l -n -r
```

#### 6.4. Troubleshooting
If the auto-xorg service fails, to diagnose review the log, execute:
```
sudo journalctl -u auto-xorg
```

Failure may be the result of absent VGA device(s), or an exception. Review the
log to debug.

### 7. How *Auto X.Org* Works
1. Runs once at boot (as a service) or run at user discretion.
2. Parses list of VGA devices:
```
lspci -m | grep --extended-regexp --ignore-case 'vga|graphics'
```

3. Saves valid and available VGA device:
&nbsp;&nbsp;- Valid example:
```
  lspci -ks 04:00.0 | grep --extended-regexp --ignore-case 'driver|VGA'

  04:00.0 VGA compatible controller: ...
  Kernel driver in use: nvidia
```
&nbsp;&nbsp;- Invalid example:
```
  lspci -ks 04:00.0 | grep --extended-regexp --ignore-case 'driver|VGA'

  01:00.0 VGA compatible controller: ...
  Kernel driver in use: vfio-pci
```

4. Appends to X.Org file: `/etc/X11/xorg.conf.d/10-auto-xorg.conf`

### 8. Filenames and Pathnames Modified by *Auto X.Org*
#### 8.1. System Files
  - `/etc/X11/xorg.conf.d/`

#### 8.2. Binaries and Files
  - `/usr/local/bin/`
  - `/etc/systemd/system/`

### 9. Contact
Did you encounter a bug? Do you need help? Please visit the
**Issues page** ([Codeberg][91], [GitHub][92]).

[91]: https://codeberg.org/portellam/auto-xorg/issues
[92]:   https://github.com/portellam/auto-xorg/issues

### 10. References
#### 1.
&nbsp;&nbsp;**PCI passthrough via OVMF**. ArchWiki. Accessed June 14, 2024.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 2.
&nbsp;&nbsp;**VFIO - ‘Virtual Function I/O’ - The Linux Kernel Documentation**.
The linux kernel. Accessed June 14, 2024.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://www.kernel.org/doc/html/latest/driver-api/vfio.html.</sup>

#### 3.
&nbsp;&nbsp;**VFIO Discussion and Support**. Reddit. Accessed June 14, 2024.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://www.reddit.com/r/VFIO/.</sup>