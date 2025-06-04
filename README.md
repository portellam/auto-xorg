# Auto X.Org
### v1.1.3
Automatically set the primary video output at boot-time given a video device
is unavailable due to hardware-passthrough (VFIO), or any other reason,
in the **X11** **(X.Org)** display server for a Linux machine.

## [Download](#5-download)
#### View this repository on [Codeberg][01], [GitHub][02].
[01]: https://codeberg.org/portellam/auto-xorg
[02]: https://github.com/portellam/auto-xorg
##

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
    - [6.1. The Command Interface (CLI) or Terminal](#61-the-command-interface-cli-or-terminal)
    - [6.2. Verify Installer is Executable](#62-verify-script-is-executable)
    - [6.3. `installer.bash` or `auto-xorg`](#63-installerbash-or-auto-xorg)
    - [6.4. Examples](#64-examples)
    - [6.5. Troubleshooting](#65-troubleshooting)
- [7. How *Auto X.Org* Works](#7-how-auto-xorg-works)
- [8. Filenames and Pathnames Modified by Generate Evdev](#8-filenames-and-pathnames-modified-by-auto-xorg)
    - [8.1. System Files](#81-system-files)
    - [8.2. Binaries and Files](#82-binaries-and-files)
- [9. Contact](#9-contact)
- [10. References](#10-references)

## Contents
### 1. Why?
By default, the **X11** **(X.Org)** display server can detect one (1) or more
GPUs, and use any or all for video output. However, should the default or
first-detected (primary) GPU be unavailable or invalid, video output may
break.

**Reasons for breakage include:**
  - *[PCI pass-through or *VFIO](#3-documentation).* This can affect all GPUs
  which share the same driver (are from the same family or manufacturer).
  - *Reservation by a running Virtual Machine (VM).* This can affect all devices
  which share the same [IOMMU group](#3-documentation). To mitigate this, a user
  may patch the Host with ACS override[<sup>[1]</sup>](#1), however this is a
  possible security risk and *is not recommended for most users.*

**Given this issue - sometimes, consecutive GPUs may only output to a Command**
**Line Interface (CLI) or terminal.**

**What can *Auto X.Org* do?** *This script may automatically set a valid GPU*
*at Host boot-time.* The user may manually set a preferred GPU, as matched by
the GPU manufacturer, should any one GPU be valid. *This flexibility is very*
*useful for a new or changing VFIO setup.*

**Warning:** *to use *Auto X.Org* at Host *run-time*, one must safely exit the
desktop (save and exit all applications), as the display manager (the entire
desktop) will be restarted.*

**Note:** *to hot-swap (hot-plug) or bind/unbind of GPUs, combine *Auto X.Org*
with any of the following methods:*
- [Optimus<sup>[2]</sup>](#2)

### 2. Related Projects
To view other relevant projects, visit [Codeberg][21]
or [GitHub][22].

[21]: https://codeberg.org/portellam/vfio-collection
[22]: https://github.com/portellam/vfio-collection

### 3. Documentation
- What is VFIO?[<sup>[3]</sup>](#3)
- VFIO Discussion and Support[<sup>[4]</sup>](#4)
- Hardware or PCI Pass-through Guide[<sup>[5]</sup>](#5)
- What is IOMMU?[<sup>[6]</sup>](#6)

### 4. Host Requirements
#### 4.1. Operating System
Linux.

#### 4.2. Software
- `systemd` for system services.
- `x11` or `xorg` or as the display server.
- Other display servers are not supported:
  - `wayland`: The author has experienced problems with `wayland` and an NVIDIA
  GPU, on Debian Linux (as of writing in 2024).

#### 4.3. Hardware
A host with two (2) or more GPUs. This includes onboard graphics or an integrated
GPU (iGPU) and one (1) or more dedicated GPU (dGPU).

A host with one GPU is not recommend, for use with this script. By default,
X.Org will output to this GPU everytime.

### 5. Download
- Download the Latest Release:&ensp;[Codeberg][51], [GitHub][52]

- Download the `.zip` file:
  - From the webpage
    1. Viewing from the top of the repository's (current) webpage, click the
        drop-down icon:
        - `···` on Codeberg.
        - `<> Code ` on GitHub.
    2. Click `Download ZIP` and save.
    3. Open the `.zip` file, then extract its contents.

  - From the CLI:
    1. Open the CLI (see [6.1. The Command Interface (CLI) or Terminal](#61-the-command-interface-cli-or-terminal)).
    2. Download the Latest:
```
GH_USER=portellam; \
GH_REPO=auto-xorg; \
GH_BRANCH=master; \
wget \
  https://github.com/${GH_USER}/${GH_REPO}/archive/refs/heads/${GH_BRANCH}.zip \
  -O "${GH_REPO}-${GH_BRANCH}.zip" \
&& unzip ./"${GH_REPO}-${GH_BRANCH}.zip" \
&& rm ./"${GH_REPO}-${GH_BRANCH}.zip"
```

- Clone the repository:
  1. Open the CLI (see [6.1. The Command Interface (CLI) or Terminal](#61-the-command-interface-cli-or-terminal)).
  2. Change your directory to your home folder or anywhere safe:
    - `cd ~`
  3. Clone the repository:
    - `git clone https://www.codeberg.org/portellam/auto-xorg`
    - `git clone https://www.github.com/portellam/auto-xorg`

[51]: https://codeberg.org/portellam/auto-xorg/releases/latest
[52]: https://github.com/portellam/auto-xorg/releases/latest

### 6. Usage
#### 6.1. The Command Interface (CLI) or Terminal
To open a CLI or Terminal:
  - Open a console emulator (for Debian systems: Konsole).
  - **Linux only:** Open an existing console: press `CTRL` + `ALT` + `F2`,
  `F3`, `F4`, `F5`, or `F6`.
    - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
    - `F1` is reserved for debug output of the Linux kernel.
    - `F7` is reserved for video output of the desktop environment.
    - `F8` and above are unused.

#### 6.2. Verify Installer is Executable
1. Open the CLI (see [6.1. The Command Interface (CLI) or Terminal](#61-the-command-interface-cli-or-terminal)).

2. Go to the directory of where the cloned/extracted repository folder is:
`cd name_of_parent_folder/auto-xorg/`

3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will perform
  this action.
    - Do **not** make any non-script file executable. This is not necessary and
  potentially dangerous.

#### 6.3. `installer.bash` or `auto-xorg`
- From within the project folder, execute: `sudo bash installer.bash`
- Or after installation, from any folder execute: `sudo bash auto-xorg`
  - The CLI's shell (bash) should recognize that the script file is located in
  `/usr/local/bin`.
```
  -h, --help              Print this help and exit.

Update X.Org:
  -r, --restart-display   Restart the display manager immediately.

Set device order:
  -f, --first             Find the first valid GPU.
  -l, --last              Find the last valid GPU.

Prefer a vendor:
  -a, --amd               AMD or ATI
  -i, --intel             Intel
  -n, --nvidia            NVIDIA
  -o, --other             Any other brand (past or future).
```

#### 6.3. Examples
- Set options to find first valid AMD/ATI GPU, then install:
```
sudo bash installer.bash -f -a
```

- Find last valid NVIDIA GPU, then restart the display manager
immediately:
```
sudo bash auto-xorg -l -n -r
```

#### 6.4. Troubleshooting
If the `auto-xorg` service fails, to diagnose review the log, execute:
```
sudo journalctl -u auto-xorg
```

Failure may be the result of absent GPU(s), or an exception. Review the
log to debug.

### 7. How *Auto X.Org* Works
1. Runs once at boot (as a service) or run at user discretion.
2. Parses a list of GPUs:
```
lspci -m \
  | grep \
    --extended-regexp \
    --ignore-case \
    'vga|graphics'
```

3. Saves valid and available GPU:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Valid example:
```
  lspci \
      -k \
      -s 04:00.0 \
    | grep \
      --extended-regexp \
      --ignore-case \
      'driver|VGA'

  04:00.0 VGA compatible controller: ...
  Kernel driver in use: nvidia
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Invalid example:
```
  lspci \
      -k \
      -s 04:00.0 \
    | grep \
      --extended-regexp \
      --ignore-case \
      'driver|VGA'

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
Do you need help? Please visit the [Issues][91] page.

[91]: https://github.com/portellam/auto-xorg/issues

### 10. References
#### 1.
&nbsp;&nbsp;**Bypassing the IOMMU groups (ACS override patch)**. ArchWiki.
Accessed June 4, 2025.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Bypassing_the_IOMMU_groups_(ACS_override_patch)
.</sup>

#### 2.
&nbsp;&nbsp;**Misairu-G/[GUIDE] Optimus laptop dGPU passthrough.md**. GitHub.
Accessed June 3, 2025.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://gist.github.com/Misairu-G/616f7b2756c488148b7309addc940b28.</sup>

&nbsp;&nbsp;**You can now passthrough your dGPU as you wish with an Optimus**
**laptop**. Reddit. Accessed June 3, 2025.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://old.reddit.com/r/VFIO/comments/7d27sz/you_can_now_passthrough_your_dgpu_as_you_wish/.</sup>

#### 3.
&nbsp;&nbsp;**VFIO - ‘Virtual Function I/O’ - The Linux Kernel Documentation**.
The linux kernel. Accessed June 14, 2024.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://www.kernel.org/doc/html/latest/driver-api/vfio.html.</sup>

#### 4.
&nbsp;&nbsp;**VFIO Discussion and Support**. Reddit. Accessed June 14, 2024.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://www.reddit.com/r/VFIO/.</sup>

#### 5.
&nbsp;&nbsp;**PCI passthrough via OVMF**. ArchWiki. Accessed June 14, 2024.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 6.
&nbsp;&nbsp;**Input-output memory management unit**. Wikipedia. Accessed June 4, 2025.

&nbsp;&nbsp;&nbsp;&nbsp;<sup>https://en.wikipedia.org/wiki/Input%E2%80%93output_memory_management_unit.</sup>
##

#### Click [here](#auto-xorg) to return to the top of this document.