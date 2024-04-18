# Auto X.Org
### v1.0.0
Automatically set the proper video output given a video device (VGA) is unavailable due to hardware-passthrough (VFIO) or any other reason, in the X.Org display environment for a Linux machine.

**[Latest release](https://github.com/portellam/auto-xorg/releases/latest) | [View develop branch...](https://github.com/portellam/auto-xorg/tree/develop)**

#### Related Projects:
**[Deploy VFIO](https://github.com/portellam/deploy-vfio) | [Generate Evdev](https://github.com/portellam/generate-evdev) | [Guest Machine Guide](https://github.com/portellam/guest-machine-guide) | [Libvirt Hooks](https://github.com/portellam/libvirt-hooks) | [Power State Virtual Machine Manager](https://github.com/portellam/powerstate-virtmanager)**

## Table of Contents
- [Why?](#why)
  - [1. Why Use This?](#1-why-use-this)
  - [2. Greater Reasoning](#2-greater-reasoning)
- [Download](#download)
- [Host Requirements](#host-requirements)
- [Usage](#usage)
  - [1. `installer.bash`](#1-installerbash)
  - [2. `auto-xorg`](#2-auto-xorg)
  - [3. Usage Examples](#3-usage-examples)
  - [4. Troubleshooting](#4-troubleshooting)
- [How It Works](#how-it-works)
- [Contact](#contact)

## Contents
### Why?
#### 1. Why Use This?
X.Org will specify a VGA device to be the primary video output. When that VGA device is *Passed-through* or restricted to Virtual Machines (VM) only (like in a VFIO setup), the VGA device cannot be used by the Host machine (Linux). Unfortunately, X.Org will not search for the next valid VGA device. *This is where auto-X.Org steps in...*

This script will automatically set the proper video output everytime, as it runs at Host startup. This flexibility is very useful for a new or changing VFIO setup.

#### 2. Greater Reasoning
The VFIO community (and greater Linux community) should break down barriers to entry into PCI passthrough on Linux. In similar attitude of my other projects, I believe high-quality scripts and tutorials should target the greatest demographic: Beginners.

This project is my first foray into Bash programming and Git since 2022. Since 2019, I've wanted to break into VFIO. My younger self would have greatly appreciated the VFIO projects I've developed thus far.

The development could not have been possible for the thorough documentation at the [ArchLinux Wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF), the helpful users at the [VFIO Reddit community](https://old.reddit.com/r/VFIO), and various other projects available here on GitHub. Please, check them out should you have any broader questions, or would like to learn more.

### Download
- To download this script, you may:
  - Download the ZIP file:
    1. Viewing from the top of the repository's (current) webpage, click the green `<> Code ` drop-down icon.
    2. Click `Download ZIP`. Save this file.
    3. Open the `.zip` file, then extract its contents.

  - Clone the repository:
    1. Open a Command Line Interface (CLI).
      - Open a console emulator (for Debian systems: Konsole).
      - Open a existing console: press `CTRL` + `ALT` + `F2`, `F3`, `F4`, `F5`, or `F6`.
        - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
        - `F1` is reserved for debug output of the Linux kernel.
        - `F7` is reserved for video output of the desktop environment.
        - `F8` and above are unused.

    2. Change your directory to your home folder or anywhere safe: `cd ~`
    3. Clone the repository: `git clone https://www.github.com/portellam/auto-xorg`

- To make this script executable, you must:
  1. Open the CLI (see above).
  2. Go to the directory of where the cloned/extracted repository folder is: `cd name_of_parent_folder/auto-xorg/`
  3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will perform this action.
    - Do **not** make any non-script file executable. This is not necessary and potentially dangerous.

### Host Requirements
- `systemd` for system services.
- `X.Org` or `X11` as the video display environment.
- `Wayland` is not supported.
  - Wayland causes problems for NVIDIA devices.
  - In general, it is [a buggy mess](https://web.archive.org/web/20240306152042/https://gist.github.com/probonopd/9feb7c20257af5dd915e3a9f2d1f2277) not ready for use.

### Usage
#### 1. `installer.bash`
- From within the project folder, execute: `sudo bash installer.bash`

```
  -h, --help       Print this help and exit.
  -i, --install    Install generate-evdev to system.
  -u, --uninstall  Uninstall generate-evdev from system.
```

#### 2. `auto-xorg`
- Execute the installer: `sudo bash installer.bash`
- Or, from any folder execute: `sudo bash auto-xorg`
  - The CLI's shell (bash) should recognize that the script file is located in `/usr/local/bin`.

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

#### 3. Usage Examples
- Set options to find first valid AMD/ATI VGA device, then install:
```
sudo bash auto-xorg.bash -f -a
```

- Find last valid NVIDIA VGA device, then restart the display manager immediately:
```
sudo bash auto-xorg -l -n -r
```

#### 4. Troubleshooting
If the auto-xorg service fails, to diagnose review the log, execute:
```
sudo journalctl -u auto-xorg
```

Failure may be the result of absent VGA device(s), or an exception. Review the log to debug.

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
Did you encounter a bug? Do you need help? Notice any dead links? Please contact by [raising an issue](https://github.com/portellam/auto-xorg/issues) with the project itself.
