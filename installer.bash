#!/bin/bash sh

#
# Filename:       installer.bash
# Description:    Installs auto-xorg.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
#

# <params>
  OPTION_STRING=""
  SORT_OPTION=""
  VENDOR_OPTION=""

  # <summary>
  # Color coding
  # Reference URL: 'https://www.shellhacks.com/bash-colors'
  # </summary>
  readonly SET_COLOR_GREEN='\033[0;32m'
  readonly SET_COLOR_RED='\033[0;31m'
  readonly SET_COLOR_YELLOW='\033[0;33m'
  readonly RESET_COLOR='\033[0m'

  # <summary>Append output</summary>
  readonly PREFIX_NOTE="${SET_COLOR_YELLOW}Note:${RESET_COLOR}"
  readonly PREFIX_ERROR="${SET_COLOR_YELLOW}An error occurred:${RESET_COLOR}"
  readonly PREFIX_FAIL="${SET_COLOR_RED}Failure:${RESET_COLOR}"
  readonly PREFIX_PASS="${SET_COLOR_GREEN}Success:${RESET_COLOR}"

  readonly PATH_1="/usr/local/bin/"
  readonly PATH_2="/etc/systemd/system/"
  readonly FILE_1="auto-xorg"
  readonly FILE_2="auto-xorg.service"
  readonly LINE_TO_REPLACE="ExecStart=/bin/bash /usr/local/bin/auto-xorg"
# </params>

# <functions>
  function Main
  {
    if ! IsUserSudo \
      || ! SetOptions "$@" \
      || ! SaveOptions \
      || ! IsSourceFileMissing "${FILE_1}" \
      || ! IsSourceFileMissing "${FILE_2}" \
      || ! WriteFile2 \
      || ! SetPermissionsForSourceFiles \
      || ! IsDestinationPathMissing "${PATH_1}" \
      || ! IsDestinationPathMissing "${PATH_2}" \
      || ! CopyFiles \
      || ! SetPermissionsForDestinationFiles \
      || ! UpdateServices; then
      echo -e "${PREFIX_FAIL} Could not install auto-Xorg."
      exit 1
    fi

    echo -e "${PREFIX_PASS} Installed auto-xorg."
    echo -e "${PREFIX_NOTE} It is NOT necessary to directly execute script '${FILE_1}'"
    echo -e "The service '${FILE_2}' will execute the script automatically at boot, to grab the first non-VFIO VGA device."
    echo -e "If no available VGA device is found, an Xorg template will be created."
    echo -e "Therefore, it will be assumed the system is running 'headless'."
    exit 0
  }

  function GetOption
  {
    while [[ "${1}" =~ ^- \
      && ! "${1}" == "--" ]]; do
      case "${1}" in
        "-f" | "--first" )
          SetOptionForSort "${1}" || return 1 ;;

        "-l" | "--last" )
          SetOptionForSort "${1}" || return 1 ;;

        "-r" | "--restart-display" )
          OPTION_STRING="${1} " ;;

        "-a" | "--amd" )
          SetOptionForVendor "${1}" || return 1 ;;

        "-i" | "--intel" )
          SetOptionForVendor "${1}" || return 1 ;;

        "-n" | "--nvidia" )
          SetOptionForVendor "${1}" || return 1 ;;

        "-o" | "--other" )
          SetOptionForVendor "${1}" || return 1 ;;

        "" )
          ;;

        "-h" | "--help" )
          PrintUsage
          exit 1 ;;

        * )
          PrintUsage
          return 1 ;;
      esac

      shift
    done

    if [[ "${1}" == '--' ]]; then
      shift
    fi

    return 0
  }

  function PrintUsage
  {
    IFS=$'\n'

    local -ar output=(
      "Usage: sudo bash installer.bash [OPTION]..."
      "  Set options for auto-Xorg in service file, then install."
      "\n    -h, --help\t\tPrint this help and exit."
      "\n  Update Xorg:"
      "    -r, --restart-display\tRestart the display manager immediately."
      "\n  Set device order:"
      "    -f, --first\t\tFind the first valid VGA device."
      "    -l, --last\t\tFind the last valid VGA device."
      "\n  Prefer a vendor:"
      "    -a, --amd\t\tAMD or ATI"
      "    -i, --intel\t\tIntel"
      "    -n, --nvidia\t\tNVIDIA"
      "    -o, --other\t\tAny other brand (past or future)."
      "\n  Example:"
      "    sudo bash installer.bash -f -a\tSet options to find first valid AMD/ATI VGA device, then install."
      "    sudo bash installer.bash -l -n -r\tSet options to find last valid NVIDIA VGA device, and restart the display manager, then install."
    )

    echo -e "${output[*]}"
    unset IFS
    return 0
  }

  function SetOptionForSort
  {
    if [[ "${SORT_OPTION}" != "" ]]; then
      echo -e "${PREFIX_ERROR} Could not add sort option. Sort option is already set."
      return 1
    fi

    readonly SORT_OPTION="${1}"
    return 0
  }

  function SetOptionForVendor
  {
    if [[ "${VENDOR_OPTION}" != "" ]]; then
      echo -e "${PREFIX_ERROR} Could not add vendor option. Vendor option is already set."
      return 1
    fi

    readonly VENDOR_OPTION="${1}"
    return 0
  }

  function SetOptions
  {
    for option in "$@"; do
      if [[ "${option}" == "" ]]; then
        return 0
      fi

      GetOption "${option}" || return 1
    done

    return 0
  }

  function SaveOptions
  {
    if [[ "${SORT_OPTION}" != "" ]]; then
      OPTION_STRING+="${SORT_OPTION} "
    fi

    if [[ "${VENDOR_OPTION}" != "" ]]; then
      OPTION_STRING+="${VENDOR_OPTION} "
    fi

    if [[ "${OPTION_STRING}" != "" ]]; then
      OPTION_STRING="${OPTION_STRING::-1}"
    fi

    readonly OPTION_STRING
    return 0
  }

  function IsUserSudo
  {
    if [[ $( whoami ) != "root" ]]; then
      echo -e "${PREFIX_ERROR} User is not sudo/root."
      return 1
    fi

    return 0
  }

  function CopyFiles
  {
    if ! cp --force "${FILE_1}" "${PATH_1}${FILE_1}" &> /dev/null \
      || ! cp --force "${FILE_2}" "${PATH_2}${FILE_2}" &> /dev/null; then
      echo -e "${PREFIX_ERROR} Failed to copy file(s)."
      return 1
    fi

    return 0
  }

  function IsDestinationPathMissing
  {
    if [[ ! -d "${1}" ]]; then
      echo -e "${PREFIX_ERROR} Could not find directory '${1}'."
      return 1
    fi

    return 0
  }

  function IsSourceFileMissing
  {
    if [[ -z "${1}" ]]; then
      echo -e "${PREFIX_ERROR} Missing project file '${1}'."
      return 1
    fi

    return 0
  }

  function SetPermissionsForSourceFiles
  {
    if ! chown --silent ${SUDO_USER}:${SUDO_USER} "${FILE_2}"; then
      echo -e "${PREFIX_ERROR} Failed to set file permissions."
      return 1
    fi

    return 0
  }

  function SetPermissionsForDestinationFiles
  {
    if ! chown --quiet root:root "${PATH_1}${FILE_1}" \
      || ! chmod --quiet +x "${PATH_1}${FILE_1}" \
      || ! chown --quiet root:root "${PATH_2}${FILE_2}" \
      || ! chmod --quiet +x "${PATH_2}${FILE_2}"; then
      echo -e "${PREFIX_ERROR} Failed to set file permissions."
      return 1
    fi

    return 0
  }

  function UpdateServices
  {
    if ! sudo systemctl daemon-reload &> /dev/null \
      || ! sudo systemctl enable "${FILE_2}" &> /dev/null \
      || ! sudo systemctl restart "${FILE_2}" &> /dev/null; then
      echo -e "${PREFIX_ERROR} Failed to update systemd with new daemon/service."
      return 1
    fi

    return 0
  }

  function WriteFile2
  {
    line_to_use="${LINE_TO_REPLACE}"

    if [[ "${OPTION_STRING}" != "" ]]; then
      line_to_use+=" ${OPTION_STRING}"
    fi

    readonly line_to_use
    local -ar file_2_contents=(
      "[Unit]"
      "Description=auto-Xorg"
      ""
      "[Service]"
      "${line_to_use}"
      "RemainAfterExit=true"
      "Type=oneshot"
      ""
      "[Install]"
      "WantedBy=multi-user.target"
    )

    IFS=$'\n'

    if ! echo -e "${file_2_contents[*]}" > "${FILE_2}"; then
      unset IFS
      return 1
    fi

    unset IFS
    return 0
  }
# </functions>

# <code>
  Main "$@"
# </code>