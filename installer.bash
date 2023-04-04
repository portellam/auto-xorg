#!/bin/bash sh

#
# Filename:         installer.bash
# Description:      Installs auto-Xorg.
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

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

# <code>
function Main
    {
        if [[ $( whoami ) != "root" ]]; then
            echo -e "$_PREFIX_ERROR User is not sudo/root."
            return 1
        fi

        declare -gr _PATH_1="/usr/local/bin/"
        declare -gr _PATH_2="/etc/systemd/system/"
        declare -gr _FILE_1="auto-xorg"
        declare -gr _FILE_2="auto-xorg.service"

        if [[ -z "$_FILE_1" ]]; then
            echo -e "$_PREFIX_ERROR Missing project file '$_FILE_1'."
            return 1
        fi

        if [[ -z "$_FILE_2" ]]; then
            echo -e "$_PREFIX_ERROR Missing project file '$_FILE_2'."
            return 1
        fi

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

        if ! sudo systemctl enable "$_FILE_2" &> /dev/null \
            || ! sudo systemctl restart "$_FILE_2" &> /dev/null \
            || ! sudo systemctl daemon-reload &> /dev/null; then
            echo -e "$_PREFIX_ERROR Failed to update systemd with new daemon/service."
            return 1
        fi

        echo -e "$_PREFIX_NOTE It is NOT necessary to directly execute script '$_FILE_1'\nThe service '$_FILE_2' will execute the script automatically at boot, to grab the first non-VFIO VGA device.\nIf no available VGA device is found, an Xorg template will be created.\nTherefore, it will be assumed the system is running 'headless'."
        return 0
    }
# </code>

# <summary> Main </summary>
# <code>
    Main

    if [[ "$?" -ne 0 ]]; then
        echo -e "$_PREFIX_FAIL Could not install auto-Xorg."
        exit 1
    fi

    echo -e "$_PREFIX_PASS Installed auto-Xorg."
    exit 0
# </code>