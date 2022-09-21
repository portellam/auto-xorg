#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.
#

# check if sudo/root #
    if [[ $(whoami) != *"root"* ]]; then
        str_file1=$(echo ${0##/*})
        str_file1=$(echo $str_file1 | cut -d '/' -f2)
        echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'.\nExiting."
        exit 1
    fi

# set IFS #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# parameters #
    bool_matchGivenIntelDriver=false                     # check to ignore 'i915' driver and prioritize 'modesetting'
    bool_parseFirstVGA=true
    bool_packageManagerIsApt=false
    bool_packageManagerIsDnf=false
    bool_packageManagerIsDpkg=false
    bool_packageManagerIsPacman=false
    bool_packageManagerIsPortage=false
    bool_packageManagerIsRpm=false
    bool_packageManagerIsYum=false
    bool_packageManagerIsZypper=false
    str_input1=$(echo $1 | tr '[:upper:]' '[:lower:]')
    str_outDir1='/etc/X11/xorg.conf.d/'
    str_outFile1=${str_outDir1}'10-auto-xorg.conf'

# match input vars
    case $str_input1 in
        "y")
            bool_parseFirstVGA=true;;

        "n")
            bool_parseFirstVGA=false
            echo -e "NOTE: Parsing VGA devices in reverse order.";;

        *)
            echo -e "FAILURE: Invalid input. Missing input variable [Y/n]. Exiting."
            exit 1;;
    esac

# parse PCI #
    if [[ $bool_parseFirstVGA == true ]]; then
        declare -a arr_PCI_ID=$(lspci -m | grep -E 'VGA|Graphics' | cut -d ' ' -f1)

    else
        declare -a arr_PCI_ID=$(lspci -m | grep -E 'VGA|Graphics' | cut -d ' ' -f1 | sort -r)
    fi

# clear existing file #
    if [[ -e $str_outFile1 ]]; then
        rm $str_outFile1
    fi

# check for package manager or distribution, then check for intel graphics driver, and set boolean #
# NOTE: this is a work in progress
    # find active package manager #
        while true; do
            if [[ $(command -v apt) ]]; then
                bool_packageManagerIsApt=true
                break
            fi

            if [[ $(command -v dnf) ]]; then
                bool_packageManagerIsDnf=true
                break
            fi

            if [[ $(command -v dpkg) ]]; then
                bool_packageManagerIsDpkg=true
                break
            fi

            if [[ $(command -v pacman) ]]; then
                bool_packageManagerIsPacman=true
                break
            fi

            if [[ $(command -v equery) ]]; then
                bool_packageManagerIsPortage=true
                break
            fi

            if [[ $(command -v rpm) ]]; then
                bool_packageManagerIsRpm=true
                break
            fi

            if [[ $(command -v yum) ]]; then
                bool_packageManagerIsYum=true
                break
            fi

            if [[ $(command -v zypper) ]]; then
                bool_packageManagerIsZypper=true
                break
            fi

            echo -e "WARNING: Package manager not found. Continuing."
            break
        done

    # check for installed package by package manager #
        # NOTE: package name or availability may not be consistent across package managers/distributions
        # NOTE: update here!

        case true in
            $bool_packageManagerIsApt)
                if [[ $(apt list --installed xserver-xorg-core xserver-xorg-video-modesetting) ]]; then     # correct package name
                    bool_matchGivenIntelDriver=true
                fi;;

            # $bool_packageManagerIsDnf)
            #     if [[ $(dnf installed xserver-xorg-core xserver-xorg-video-modesetting)  ]]; then           # incorrect package name
            #         bool_matchGivenIntelDriver=true
            #     fi;;

            $bool_packageManagerIsDpkg)
                if [[ $(dpkg -l | grep -E 'xserver-xorg-core|xserver-xorg-video-modesetting') ]]; then      # correct package name
                    bool_matchGivenIntelDriver=true
                fi;;

            # $bool_packageManagerIsPacman)
            #     if [[ $(pacman -Qi xserver-xorg-core xserver-xorg-video-modesetting) ]]; then               # incorrect package name
            #         bool_matchGivenIntelDriver=true
            #     fi;;

            # $bool_packageManagerIsPortage)
            #     if [[ $(equery list xserver-xorg-core xserver-xorg-video-modesetting) ]]; then              # incorrect package name
            #         bool_matchGivenIntelDriver=true
            #     fi;;

            # $bool_packageManagerIsRpm)
            #     if [[ $(rpm -qa xserver-xorg-core xserver-xorg-video-modesetting) ]]; then                  # incorrect package name
            #         bool_matchGivenIntelDriver=true
            #     fi;;

            # $bool_packageManagerIsYum)
            #     if [[ $(yum list installed xserver-xorg-core xserver-xorg-video-modesetting) ]]; then       # incorrect package name
            #         bool_matchGivenIntelDriver=true
            #     fi;;

            # $bool_packageManagerIsZypper)
            #     if [[ $(zypper search -i xserver-xorg-core xserver-xorg-video-modesetting) ]]; then         # incorrect package name
            #         bool_matchGivenIntelDriver=true
            #     fi;;
        esac

# find first/last valid VGA driver #
    for str_thisPCI_ID in ${arr_PCI_ID}; do

        # parameters #
        str_thisDriver=$(lspci -ks $str_thisPCI_ID | grep -E 'driver' | cut -d ':' -f2 | cut -d ' ' -f2)
        str_thisType=$(lspci -ms $str_thisPCI_ID | cut -d '"' -f2 | tr '[:upper:]' '[:lower:]')
        str_thisVendor=$(lspci -ms $str_thisPCI_ID | cut -d '"' -f4 | tr '[:upper:]' '[:lower:]')
        # str_thisBusID=$(echo $str_thisPCI_ID | cut -d ':' -f1)
        # str_thisSlotID=$(echo $str_thisPCI_ID | cut -d ':' -f2 | cut -d '.' -f1)
        str_thisFuncID=$(echo $str_thisPCI_ID | cut -d '.' -f2)
        str_thisPCI_ID=$(echo $str_thisPCI_ID | cut -d '.' -f1)

        # rearrange string for Xorg output #
        # str_thisPCI_ID=${str_thisBusID}":"${str_thisSlotID}":"${str_thisFuncID}
        str_thisPCI_ID+=":"${str_thisFuncID}

        echo -e "Found PCI ID: '$str_thisPCI_ID'"

        # match valid VGA device and driver #
        if [[ ($str_thisType == *"vga"* || $str_thisType == *"graphics" ) && ( -e $str_thisDriver || $str_thisDriver != "" ) && $str_thisDriver != *"vfio-pci"* ]]; then

            echo -e "Found Driver: '$str_thisDriver'"

            if [[ $str_thisVendor == "*intel"* ]]; then
                echo -e "WARNING: Should given parsed Intel VGA driver be invalid, replace xorg.conf with an alternate intel driver (example: 'modesetting')."
            fi

            # if [[ $str_thisVendor == "*intel"* && $bool_matchGivenIntelDriver == true ]]; then
            #     str_thisDriver="modesetting"
            # fi

            readonly str_thisPCI_ID
            readonly str_thisDriver
            break

        elif [[ $str_thisDriver == "" ]]; then
            echo -e "Found Driver: 'N/A'"

        else
            echo -e "Found Driver: '$str_thisDriver'"
        fi
    done

# write to file #
    if [[ -e $str_outDir1 ]]; then

        # valid xorg #
        if [[ $str_thisDriver != "" ]]; then
            echo -e "Valid VGA device found."

            declare -a arr_output1=(
"# Generated by 'portellam/Auto-Xorg'
#
# WARNING: Any modifications to this file will be modified by 'Auto-Xorg'
#
# Execute \"lspci -k\" for Bus ID and Driver.
#
\nSection\t\"Device\"
\tIdentifier\t\"Device0\"
\tDriver\t\t\"$str_thisDriver\"
\tBusID\t\t\"PCI:$str_thisPCI_ID\"
EndSection")

            # append file #
            for str_line1 in ${arr_output1[@]}; do
                echo -e $str_line1 >> $str_outFile1
            done

            # # find display manager #
            str_DM=$(cat /etc/X11/default-display-manager)

            if [[ -e $str_DM && $str_DM != "" ]]; then
                str_DM="${str_DM##*/}"

                # restart service #
                str_input2=$(echo $2 | tr '[:upper:]' '[:lower:]')

                if [[ $str_input2 == "dm"* ]]; then
                    sudo systemctl enable $str_DM
                    sudo systemctl restart $str_DM
                fi

                if [[ $str_input2 != "dm"* ]]; then
                    echo -e "You may restart the active display manager ($str_DM).\nExecute 'systemctl restart $str_DM'."
                fi
            else
                echo -e "WARNING: No default display manager found. Continuing."
            fi

        # template #
        else
            echo -e "WARNING: No valid VGA device found. Continuing."

            declare -a arr_output1=(
"# Generated by 'portellam/Auto-Xorg'
#
# WARNING: Any modifications to this file will be modified by 'Auto-Xorg'
#
# Execute 'lspci -k' for Bus ID and Driver.
#
\n#Section\t\"Device\"
#\tIdentifier\t\"Device0\"
#\tDriver\t\t\"driver_name\"
#\tBusID\t\t\"PCI:bus_id:slot_id:function_id\"
#EndSection")

            # append file #
            for str_line1 in ${arr_output1[@]}; do
                echo -e $str_line1 >> $str_outFile1
            done
        fi

# missing files #
    else
        echo -e "FAILURE: Missing directories/files:"

        if [[ -z $str_outDir1 ]]; then
            echo -e "\t$str_outDir1"
        fi

        if [[ -z $str_outDir1$str_outFile1 ]]; then
            echo -e "\t$str_outDir1$str_outFile1"
        fi

        echo -e "Exiting."
        exit 1
    fi

IFS=$SAVEIFS   # Restore original IFS
exit 0
