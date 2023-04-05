#!/bin/bash sh

#
# Filename:         installer.bash
# Description:      Installs auto-Xorg.
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <params>
    declare -g _OPTIONS=""
    declare -g __SORT_OPTION=""
    declare -g _VENDOR_OPTION=""

    # <summary>
    # Color coding
    # Reference URL: 'https://www.shellhacks.com/bash-colors'
    # </summary>
    declare -gr _SET_COLOR_GREEN='\033[0;32m'
    declare -gr _SET_COLOR_RED='\033[0;31m'
    declare -gr _SET_COLOR_YELLOW='\033[0;33m'
    declare -gr _RESET_COLOR='\033[0m'

    # <summary> Append output </summary>
    declare -gr _PREFIX_NOTE="${_SET_COLOR_YELLOW}Note:${_RESET_COLOR}"
    declare -gr _PREFIX_ERROR="${_SET_COLOR_YELLOW}An error occurred:${_RESET_COLOR}"
    declare -gr _PREFIX_FAIL="${_SET_COLOR_RED}Failure:${_RESET_COLOR}"
    declare -gr _PREFIX_PASS="${_SET_COLOR_GREEN}Success:${_RESET_COLOR}"
# </params>

# <code>
    # <summary> Gets the current option </summary>
    function GetOption
    {
        while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
            "-f" | "--first" )
                SetOptionForSort "$1" || return 1 ;;

            "-l" | "--last" )
                SetOptionForSort "$1" || return 1 ;;

            "-r" | "--restart-display" )
                _OPTIONS="$1 " ;;

            "-a" | "--amd" )
                SetOptionForVendor "$1" || return 1 ;;

            "-i" | "--intel" )
                SetOptionForVendor "$1" || return 1 ;;

            "-n" | "--nvidia" )
                SetOptionForVendor "$1" || return 1 ;;

            "-o" | "--other" )
                SetOptionForVendor "$1" || return 1 ;;

            "" )
                ;;

            "-h" | "--help" )
                GetUsage
                return 1 ;;
        esac; shift; done

        while ! [[ "$1" =~ ^- && "$1" == "--" ]]; do case $1 in
            * )
                echo -e "$_PREFIX_ERROR Invalid input."
                GetUsage
                return 1 ;;
        esac; shift; done

        if [[ "$1" == '--' ]]; then
            shift
        fi

        return 0
    }

    # <summary> Gets the usage. </summary>
    function GetUsage
    {
        IFS=$'\n'

        local -ar _OUTPUT=(
            "Usage: sudo bash installer.bash [OPTION]..."
            "Set options for auto-Xorg in service file, then install."
            "\n  -h, --help\t\tPrint this help and exit."
            "\nUpdate Xorg:"
            "  -r, --restart-display\tRestart the display manager immediately."
            "\nSet device order:"
            "  -f, --first\t\tFind the first valid VGA device."
            "  -l, --last\t\tFind the last valid VGA device."
            "\nPrefer a vendor:"
            "  -a, --amd\t\tAMD or ATI"
            "  -i, --intel\t\tIntel"
            "  -n, --nvidia\t\tNVIDIA"
            "  -o, --other\t\tAny other brand (past or future)."
            "\nExample:"
            "  sudo bash installer.bash -f -a\tSet options to find first valid AMD/ATI VGA device, then install."
            "  sudo bash installer.bash -l -n -r\tSet options to find last valid NVIDIA VGA device, and restart the display manager, then install."
        )

        echo -e "${_OUTPUT[*]}"
        unset IFS
        return 0
    }

    function SetOptionForSort
    {
        if [[ "$_SORT_OPTION" != "" ]]; then
            echo -e "$_PREFIX_ERROR Could not add sort option. Sort option is already set."
            return 1
        fi

        readonly _SORT_OPTION="$1"
        return 0
    }

    function SetOptionForVendor
    {
        if [[ "$_VENDOR_OPTION" != "" ]]; then
            echo -e "$_PREFIX_ERROR Could not add vendor option. Vendor option is already set."
            return 1
        fi

        readonly _VENDOR_OPTION="$1"
        return 0
    }

    # <summary> Sets the options. Exit early (Pass) if input is null. Else, exit early (Fail) if input is invalid. </summary>
    function SetOptions
    {
        for VAR_OPTION in "$@"; do
            [ "$VAR_OPTION" == "" ] && return 0
            GetOption "$VAR_OPTION" || return "$?"
        done

        return 0
    }

    function Main
    {
        if [[ $( whoami ) != "root" ]]; then
            echo -e "$_PREFIX_ERROR User is not sudo/root."
            return 1
        fi

        if [[ "$_SORT_OPTION" != "" ]]; then
            _OPTIONS+="$_SORT_OPTION "
        fi

        if [[ "$_VENDOR_OPTION" != "" ]]; then
            _OPTIONS+="$_VENDOR_OPTION "
        fi

        if [[ "$_OPTIONS" != "" ]]; then
            readonly _OPTIONS="${_OPTIONS::-1}"
        fi

        local -r _PATH_1="/usr/local/bin/"
        local -r _PATH_2="/etc/systemd/system/"
        local -r _FILE_1="auto-xorg"
        local -r _FILE_2="auto-xorg.service"
        local -r _LINE_TO_REPLACE="ExecStart=/bin/bash /usr/local/bin/auto-xorg"
        local _LINE_TO_USE="$_LINE_TO_REPLACE"

        if [[ "$_OPTIONS" != "" ]]; then
            _LINE_TO_USE+=" $_OPTIONS"
        fi

        readonly _LINE_TO_USE
        local -r _FILE_2_CONTENTS=(
            "[Unit]"
            "Description=auto-Xorg"
            ""
            "[Service]"
            "$_LINE_TO_USE"
            "RemainAfterExit=true"
            "Type=oneshot"
            ""
            "[Install]"
            "WantedBy=multi-user.target"
        )

        if [[ -z "$_FILE_1" ]]; then
            echo -e "$_PREFIX_ERROR Missing project file '$_FILE_1'."
            return 1
        fi

        if [[ -z "$_FILE_2" ]]; then
            echo -e "$_PREFIX_ERROR Missing project file '$_FILE_2'."
            return 1
        fi

        IFS=$'\n'
        echo -e "${_FILE_2_CONTENTS[*]}" > "$_FILE_2"
        unset IFS

        if [[ "$?" -ne 0 ]]; then
            echo -e "$_PREFIX_ERROR Could not write to file '$_FILE_2'."
            return 1
        fi

        if ! chown $SUDO_USER:$SUDO_USER "$_FILE_2" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to set file permissions."
            return 1
        fi

        exit 1

        if [[ ! -d "$_PATH_1" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_PATH_1'."
            return 1
        fi

        if [[ ! -d "$_PATH_2" ]]; then
            echo -e "$_PREFIX_ERROR Could not find directory '$_PATH_2'."
            return 1
        fi

        if ! cp "$_FILE_1" "$_PATH_1$_FILE_1" &> /dev/null \
            || ! cp "$_FILE_2" "$_PATH_2$_FILE_2" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to copy file(s)."
            return 1
        fi

        if ! chown root:root "$_PATH_1$_FILE_1" &> /dev/null \
            || ! chmod +x "$_PATH_1$_FILE_1" &> /dev/null \
            || ! chown root:root "$_PATH_2$_FILE_2" &> /dev/null \
            || ! chmod +x "$_PATH_2$_FILE_2" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to set file permissions."
            return 1
        fi

        if || ! sudo systemctl daemon-reload &> /dev/null \
            || ! sudo systemctl enable "$_FILE_2" &> /dev/null \
            || ! sudo systemctl restart "$_FILE_2" &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to update systemd with new daemon/service."
            return 1
        fi

        echo -e "$_PREFIX_NOTE It is NOT necessary to directly execute script '$_FILE_1'\nThe service '$_FILE_2' will execute the script automatically at boot, to grab the first non-VFIO VGA device.\nIf no available VGA device is found, an Xorg template will be created.\nTherefore, it will be assumed the system is running 'headless'."
        return 0
    }
# </code>

# <summary> Main </summary>
# <code>
    if [[ "$@" != "" ]]; then
        SetOptions "$@" || exit "$?"
    fi

    Main

    if [[ "$?" -ne 0 ]]; then
        echo -e "$_PREFIX_FAIL Could not install auto-Xorg."
        exit 1
    fi

    echo -e "$_PREFIX_PASS Installed auto-Xorg."
    exit 0
# </code>