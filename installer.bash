#!/bin/bash/env bash

#
# Filename:       installer.bash
# Description:    Installs Auto X.Org.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
# Version:        1.1.3
#

#region Traps

trap 'catch_error' SIGINT SIGTERM ERR
trap 'catch_exit' EXIT

#endregion

#region Parameters

declare -r SCRIPT_VERSION="1.1.3"
declare -r SCRIPT_NAME="$( basename "${0}" )"
declare -r PREFIX_PROMPT="${SCRIPT_NAME}: "

SAVEIFS="${IFS}"
IFS=$'\n'

OPTION_STRING=""
SORT_OPTION=""
VENDOR_OPTION=""

  #region Color coding

  # Reference URL : 'https://www.shellhacks.com/bash-colors'
  declare -r SET_COLOR_GREEN='\033[0;32m'
  declare -r SET_COLOR_RED='\033[0;31m'
  declare -r SET_COLOR_YELLOW='\033[0;33m'
  declare -r RESET_COLOR='\033[0m'

  #endregion

  #region Append output

  declare -r PREFIX_ERROR="${SET_COLOR_RED}An error occurred:${RESET_COLOR} "
  declare -r PREFIX_NOTE="${SET_COLOR_YELLOW}Note:${RESET_COLOR} "
  declare -r PREFIX_PASS="${SET_COLOR_GREEN}Success:${RESET_COLOR} "

  #endregion

declare -r PATH_1="/usr/local/bin/"
declare -r PATH_2="/etc/systemd/system/"
declare -r FILE_1="auto-xorg"
declare -r FILE_2="${FILE_1}.service"
declare -r LINE_TO_REPLACE="ExecStart=/bin/bash /usr/local/bin/${FILE_1}"

#endregion

#region Logic

#
# $@  : the command line arguments.
#
function main
{
  if ! is_user_superuser \
    || ! set_options "$@" \
    || ! save_options \
    || ! is_source_file_missing "${FILE_1}" \
    || ! is_source_file_missing "${FILE_2}" \
    || ! update_source_service_file \
    || ! set_permissions_for_source_files \
    || ! is_destination_path_found "${PATH_1}" \
    || ! is_destination_path_found "${PATH_2}" \
    || ! copy_files \
    || ! set_permissions_for_destination_files \
    || ! update_services; then
    print_to_error_log "Could not install ${FILE_1}."
    print_usage
  fi

  print_to_output_log "${PREFIX_PASS}Installed ${FILE_1}."

  echo -e \
    "${PREFIX_NOTE}It is NOT necessary to directly execute script'${FILE_1}'."

  echo -e \
    "The service '${FILE_1}' will execute the script automatically at boot," \
    "to grab the first non-VFIO VGA device."

  echo -e \
    "If no available VGA device is found, an Xorg template will be created."

  echo -e \
    "Therefore, it will be assumed the system is running 'headless'."

  exit 0
}

  #region Business logic

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function copy_files
  {
    if ! cp --force "${FILE_1}" "${PATH_1}${FILE_1}" &> /dev/null \
      || ! cp --force "${FILE_2}" "${PATH_2}${FILE_2}" &> /dev/null; then
      print_to_error_log "Failed to copy file(s)."
      return 1
    fi

    print_to_output_log "Copied file(s)."
  }

  #
  # $1  : the directory name.
  # $?  : on success, return 0; on failure, return 1.
  #
  function is_destination_path_found
  {
    if [[ ! -d "${1}" ]]; then
      print_to_error_log "Could not find directory '${1}'."
      return 1
    fi
  }

  #
  # $1  : the source file name.
  # $?  : on success, return 0; on failure, return 1.
  #
  function is_source_file_missing
  {
    if [[ ! -e "${1}" ]]; then
      print_to_error_log "Missing source file '${1}'."
      return 1
    fi
  }

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function set_permissions_for_source_files
  {
    if ! chown --silent "${SUDO_USER}":"${SUDO_USER}" "${FILE_2}"; then
      print_to_error_log "Failed to set source file permissions."
      return 1
    fi

    print_to_output_log "Set source file permissions."
  }

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function set_permissions_for_destination_files
  {
    if ! chown --quiet root:root "${PATH_1}${FILE_1}" \
      || ! chmod --quiet +x "${PATH_1}${FILE_1}" \
      || ! chown --quiet root:root "${PATH_2}${FILE_2}" \
      || ! chmod --quiet +x "${PATH_2}${FILE_2}"; then
      print_to_error_log "Failed to set destination file permissions."
      return 1
    fi

    print_to_output_log "Set destination file permissions."
  }

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function update_services
  {
    if ! sudo systemctl daemon-reload &> /dev/null \
      || ! sudo systemctl enable "${FILE_2}" &> /dev/null \
      || ! sudo systemctl restart "${FILE_2}" &> /dev/null; then
      print_to_error_log "Failed to update services."
      return 1
    fi

    print_to_output_log "Updated services."
  }

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function update_source_service_file
  {
    line_to_use="${LINE_TO_REPLACE}"

    if is_string "${OPTION_STRING}" &> /dev/null; then
      line_to_use+=" ${OPTION_STRING}"
    fi

    readonly line_to_use

    local -ar file_2_contents=(
      "[Unit]"
      "Description=Auto X.Org"
      ""
      "[Service]"
      "${line_to_use}"
      "RemainAfterExit=true"
      "Type=oneshot"
      ""
      "[Install]"
      "WantedBy=multi-user.target"
    )

    if ! echo -e "${file_2_contents[*]}" > "${FILE_2}"; then
      return 1
    fi
  }

  #endregion

  #region Options logic

  #
  # $1  : the option.
  # $?  : on success, return 0; on failure, return 1.
  #
  function get_option
  {
    while [[ "${1}" =~ ^- \
      && ! "${1}" == "--" ]]; do
      case "${1}" in
        "-f" | "--first" )
          set_option_for_sort "${1}" || return 1 ;;

        "-l" | "--last" )
          set_option_for_sort "${1}" || return 1 ;;

        "-r" | "--restart-display" )
          OPTION_STRING="${1} " ;;

        "-a" | "--amd" )
          set_option_for_vendor "${1}" || return 1 ;;

        "-i" | "--intel" )
          set_option_for_vendor "${1}" || return 1 ;;

        "-n" | "--nvidia" )
          set_option_for_vendor "${1}" || return 1 ;;

        "-o" | "--other" )
          set_option_for_vendor "${1}" || return 1 ;;

        "" )
          ;;

        "-h" | "--help" )
          print_usage ;;

        * )
          echo -e "${PREFIX_ERROR} Invalid input."
          return 1 ;;
      esac

      shift
    done

    if [[ "${1}" == '--' ]]; then
      shift
    fi
  }

  #
  # $?  : always exits 1.
  #
  function print_usage
  {
    echo -e \
      "Usage: bash ${SCRIPT_NAME} [OPTION]..." \
      "\n" \
      "  Set options for ${FILE_1} in service file, then install." \
      "\n" \
      "  Version ${SCRIPT_VERSION}." \
      "\n" \
      "\n" \
      "    -h, --help\t\tPrint this help and exit." \
      "\n" \
      "\n" \
      "  Update X.Org:" \
      "\n" \
      "    -r, --restart-display\tRestart the display server immediately." \
      "\n" \
      "\n" \
      "  Set device order:" \
      "\n" \
      "    -f, --first\tFind the first valid VGA device." \
      "\n" \
      "    -l, --last\t\tFind the last valid VGA device." \
      "\n" \
      "\n" \
      "  Prefer a vendor:" \
      "\n" \
      "    -a, --amd\t\tAMD or ATI" \
      "\n" \
      "    -i, --intel\tIntel" \
      "\n" \
      "    -n, --nvidia\tNVIDIA" \
      "\n" \
      "    -o, --other\tAny other brand (past or future)." \
      "\n" \
      "  Example:" \
      "\n" \
      "    sudo bash ${SCRIPT_NAME} --first --amd\tSet options to find first"\
        "valid AMD/ATI VGA device, then install." \
      "\n" \
      "    sudo bash ${SCRIPT_NAME} --last --nvidia --restart-display\tSet"\
        "options to find last valid NVIDIA VGA device, and restart the display"\
        "server, then install."

    exit 1
  }

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function set_option_for_sort
  {
    if [[ "${SORT_OPTION}" != "" ]]; then
      print_to_error_log \
        "Could not add sort option. Sort option is already set."

      return 1
    fi

    readonly SORT_OPTION="${1}"
  }

  #
  # $?  : on success, return 0; on failure, return 1.
  #
  function set_option_for_vendor
  {
    if [[ "${VENDOR_OPTION}" != "" ]]; then
      print_to_error_log \
        "Could not add vendor option. Vendor option is already set."

      return 1
    fi

    readonly VENDOR_OPTION="${1}"
  }

  #
  # $@  : the options.
  # $?  : on success, return 0; on failure, return 1.
  #
  function set_options
  {
    for option in "$@"; do
      if ! is_string "${option}" &> /dev/null; then
        return 0
      fi

      get_option "${option}" || return 1
    done
  }

  #
  # $?  : always returns 0.
  #
  function save_options
  {
    if is_string "${SORT_OPTION}" &> /dev/null; then
      OPTION_STRING+="${SORT_OPTION} "
    fi

    if is_string "${VENDOR_OPTION}" &> /dev/null; then
      OPTION_STRING+="${VENDOR_OPTION} "
    fi

    if is_string "${OPTION_STRING}" &> /dev/null; then
      OPTION_STRING="${OPTION_STRING::-1}"
    fi

    readonly OPTION_STRING
  }

  #endregion

  #region Clean-up

  #
  # $?  : always returns 0.
  #
  function reset_ifs
  {
    IFS="${SAVEIFS}"
  }

  #endregion

  #region Data-type validation

  #
  # $1  : the string.
  # $?  : if not empty string, return 0.
  #
  function is_string
  {
    if [[ "${1}" == "" ]]; then
      return 1
    fi
  }

  #endregion

  #region Handlers

  #
  # $?  : always exits non-zero.
  #
  function catch_error
  {
    exit 255
  }

  #
  # $?  : always returns 0.
  #
  function catch_exit
  {
    reset_ifs
  }

  #
  # $?  : if user is root, return 0.
  #
  function is_user_superuser
  {
    if [[ $( whoami ) != "root" ]]; then
      print_to_error_log "User is not sudo or root."
      return 1
    fi
  }

  #endregion

  #region Loggers

  #
  # $1  : the output.
  # $?  : always returns 0.
  #
  function print_to_error_log
  {
    echo -e "${PREFIX_PROMPT}${PREFIX_ERROR}${*}" >&2
  }

  #
  # $1  : the output.
  # $?  : always returns 0.
  #
  function print_to_output_log
  {
    echo -e "${PREFIX_PROMPT}${*}" >&1
  }

  #endregion

#endregion

#region Main

main "$@"

#endregion