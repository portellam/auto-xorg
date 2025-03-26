#!/bin/bash/env bash

#
# Filename:       installer.bash
# Description:    Installs Auto X.Org.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
# Version:        1.1.2
#

# <traps>
  trap 'catch_error' SIGINT SIGTERM ERR
  trap 'catch_exit' EXIT
# </traps>

# <params>
  declare -r SCRIPT_VERSION="1.1.2"
  declare -r SCRIPT_NAME="$( basename "${0}" )"
  declare -r PREFIX_PROMPT="${SCRIPT_NAME}: "

  SAVEIFS="${IFS}"
  IFS=$'\n'

  OPTION_STRING=""
  SORT_OPTION=""
  VENDOR_OPTION=""

  # <summary>
  # Color coding
  # Reference URL: 'https://www.shellhacks.com/bash-colors'
  # </summary>
    declare -r SET_COLOR_GREEN='\033[0;32m'
    declare -r SET_COLOR_RED='\033[0;31m'
    declare -r SET_COLOR_YELLOW='\033[0;33m'
    declare -r RESET_COLOR='\033[0m'

  # <summary>Append output</summary>
    declare -r PREFIX_ERROR="${SET_COLOR_RED}An error occurred:${RESET_COLOR} "
    declare -r PREFIX_NOTE="${SET_COLOR_YELLOW}Note:${RESET_COLOR} "
    declare -r PREFIX_PASS="${SET_COLOR_GREEN}Success:${RESET_COLOR} "

  declare -r PATH_1="/usr/local/bin/"
  declare -r PATH_2="/etc/systemd/system/"
  declare -r FILE_1="auto-xorg"
  declare -r FILE_2="${FILE_1}.service"
  declare -r LINE_TO_REPLACE="ExecStart=/bin/bash /usr/local/bin/${FILE_1}"
# </params>

# <functions>
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
      exit 1
    fi

    print_to_output_log "${PREFIX_PASS}Installed ${FILE_1}."
    echo -e "${PREFIX_NOTE}It is NOT necessary to directly execute script '${FILE_1}'."
    echo -e "The service '${FILE_1}' will execute the script automatically at boot, to grab the first non-VFIO VGA device."
    echo -e "If no available VGA device is found, an Xorg template will be created."
    echo -e "Therefore, it will be assumed the system is running 'headless'."
    exit 0
  }

  # <summary>Clean-up</summary>
    function reset_ifs
    {
      IFS="${SAVEIFS}"
    }

  # <summary>Data-type validation</summary>
    function is_string
    {
      if [[ "${1}" == "" ]]; then
        return 1
      fi
    }

  # <summary>Handlers</summary>
    function catch_error {
      exit 255
    }

    function catch_exit {
      reset_ifs
    }

    function is_user_superuser
    {
      if [[ $( whoami ) != "root" ]]; then
        print_to_error_log "User is not sudo or root."
        return 1
      fi
    }

  # <summary>Loggers</summary>
    function print_to_error_log
    {
      echo -e "${PREFIX_PROMPT}${PREFIX_ERROR}${1}" >&2
    }

    function print_to_output_log
    {
      echo -e "${PREFIX_PROMPT}${1}" >&1
    }

  # <summary>Options logic</summary>
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
            print_usage
            exit 1 ;;

          * )
            print_usage
            return 1 ;;
        esac

        shift
      done

      if [[ "${1}" == '--' ]]; then
        shift
      fi
    }

    function print_usage
    {
      local -ar output=(
        "Usage: bash ${SCRIPT_NAME} [OPTION]..."
        "  Set options for ${FILE_1} in service file, then install."
        "  Version ${SCRIPT_VERSION}."
        "\n    -h, --help\t\t\tPrint this help and exit."
        "\n  Update X.Org:"
        "    -r, --restart-display\tRestart the display manager immediately."
        "\n  Set device order:"
        "    -f, --first\t\tFind the first valid VGA device."
        "    -l, --last\t\tFind the last valid VGA device."
        "\n  Prefer a vendor:"
        "    -a, --amd\t\tAMD or ATI"
        "    -i, --intel\t\tIntel"
        "    -n, --nvidia\tNVIDIA"
        "    -o, --other\t\tAny other brand (past or future)."
        "\n  Example:"
        "    sudo bash installer.bash -f -a\tSet options to find first valid AMD/ATI VGA device, then install."
        "    sudo bash installer.bash -l -n -r\tSet options to find last valid NVIDIA VGA device, and restart the display manager, then install."
      )

      echo -e "${output[*]}"
    }

    function set_option_for_sort
    {
      if [[ "${SORT_OPTION}" != "" ]]; then
        print_to_error_log "Could not add sort option. Sort option is already set."
        return 1
      fi

      readonly SORT_OPTION="${1}"
    }

    function set_option_for_vendor
    {
      if [[ "${VENDOR_OPTION}" != "" ]]; then
        print_to_error_log "Could not add vendor option. Vendor option is already set."
        return 1
      fi

      readonly VENDOR_OPTION="${1}"
    }

    function set_options
    {
      for option in "$@"; do
        if ! is_string "${option}" &> /dev/null; then
          return 0
        fi

        get_option "${option}" || return 1
      done
    }

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

  function copy_files
  {
    if ! cp --force "${FILE_1}" "${PATH_1}${FILE_1}" &> /dev/null \
      || ! cp --force "${FILE_2}" "${PATH_2}${FILE_2}" &> /dev/null; then
      print_to_error_log "Failed to copy file(s)."
      return 1
    fi

    print_to_output_log "Copied file(s)."
  }

  function is_destination_path_found
  {
    if [[ ! -d "${1}" ]]; then
      print_to_error_log "Could not find directory '${1}'."
      return 1
    fi
  }

  function is_source_file_missing
  {
    if [[ ! -e "${1}" ]]; then
      print_to_error_log "Missing source file '${1}'."
      return 1
    fi
  }

  function set_permissions_for_source_files
  {
    if ! chown --silent ${SUDO_USER}:${SUDO_USER} "${FILE_2}"; then
      print_to_error_log "Failed to set source file permissions."
      return 1
    fi

    print_to_output_log "Set source file permissions."
  }

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
# </functions>

# <code>
  main "$@"
# </code>