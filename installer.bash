#!/bin/bash sh

#
# Filename:         installer.bash
# Description:      Installs auto-Xorg.
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <code>
    function Main
    {
        local _PREFIX_ERROR="An error occurred:"

        if [[ $( whoami ) != "root" ]]; then
            echo -e "$_PREFIX_ERROR User is not sudo/root."
            return 1
        fi

        readonly _PATH_1="/usr/local/bin/"
        readonly _PATH_2="/etc/systemd/system/"
        readonly _FILE_1="auto-xorg.bash"
        readonly _FILE_2="auto-xorg.service"

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

        if ! [ cp "$_FILE_1" "$_PATH_1$_FILE_1" ] \
            || ! [ cp "$_FILE_2" "$_PATH_2$_FILE_2" ]; then
            echo -e "$_PREFIX_ERROR Failed to copy file(s)."
            return 1
        fi

        if ! [ chown root:root "$_PATH_1$_FILE_1" ] \
            || ! [ chmod +x "$_PATH_1$_FILE_1" ] \
            || ! [ chown root:root "$_PATH_2$_FILE_2" ] \
            || ! [ chmod +x "$_PATH_2$_FILE_2" ]; then
            echo -e "$_PREFIX_ERROR Failed to set file permissions."
            return 1
        fi

        if ! [ sudo systemctl enable $_FILE_2 ] \
            || ! [ sudo systemctl restart $_FILE_2 ] \
            || ! [ sudo systemctl daemon-reload ]; then
            echo -e "$_PREFIX_ERROR Failed to update systemd with new daemon/service."
            return 1
        fi

        echo -e "Note: It is NOT necessary to directly execute script '$_FILE_1'\n The service '$_FILE_2' will execute the script automatically at boot, to grab the first non-VFIO VGA device.\nIf no available VGA device is found, an Xorg template will be created.\nTherefore, it will be assumed the system is running 'headless'."
        return 0
    }
# </code>

# <summary> Main </summary>
# <code>
    Main
    echo -en "Installing Auto-Xorg... "

    if [[ $? -ne 0 ]]; then
        echo -e "Failed."
        exit 1
    fi

    echo -e "Success."
    exit 0
# </code>