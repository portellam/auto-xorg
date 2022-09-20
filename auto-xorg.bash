#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.
#

# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file1=`echo ${0##/*}`
        str_file1=`echo $str_file1 | cut -d '/' -f2`
        echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'.\nExiting."
        exit 1
    fi

# set IFS #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# parameters #
    declare -a arr_driver=()
    bool_matchGivenIntelDriver=false                     # check to ignore 'i915' driver and prioritize 'modesetting'
    bool_parseFirstVGA=true
    str_input1=$(echo $1 | tr '[:upper:]' '[:lower:]')
    str_outDir1='/etc/X11/xorg.conf.d/'
    str_outFile1=${str_outDir1}'10-auto-xorg.conf'

# match input vars
    case $str_input1:
        "y":
            bool_parseFirstVGA=true
            break;;

        "n":
            bool_parseFirstVGA=false
            echo -e "NOTE: Parsing VGA devices in reverse order."
            break;;

        *:
            echo -e "FAILURE: Invalid input. Missing input variable [Y/n]. Exiting."
            exit 1;;
    case;

    if [[ $str_input1 == "y"* && $str_input1 != "" ]]; then
        bool_parseFirstVGA=true

    else
        bool_parseFirstVGA=false
    fi

# parse PCI #
    if [[ $bool_parseFirstVGA == true ]]; then
        declare -a arr_busID=$(lspci -m | grep -E 'VGA|Graphics' | cut -d ' ' -f1)

    else
        declare -a arr_busID=$(lspci -m | grep -E 'VGA|Graphics' | cut -d ' ' -f1 | sort -r)
    fi

# clear existing file #
    if [[ -e $str_outFile1 ]]; then
        rm $str_outFile1
    fi

# NOTE: incomplete
# find distro name, parse installed packages for updated intel driver #
#     case $(lsb_release -is | tr '[:upper:]' '[:lower:]'):
#         *"debian"*|*"ubuntu"*:
#             bool_matchDistroDebian=true
#             break;;

#         *"red"*|*"hat"*|*"fedora"*:
#             bool_matchDistroRedhat=true
#             break;;

#         *"arch"*:
#             bool_matchDistroArch=true
#             break;;

#         *:
#             echo -e "WARNING: Unrecognized Linux distribution. Continuing with minimum function."
#             break;;
#     esac

# parse for and note problematic intel driver #
    for str_thisBusID in ${arr_busID}; do

        # match valid VGA device and driver #
        if [[ $str_thisType == *"vga"* && $str_thisVendor == *"intel" && -e $str_thisDriver && $str_thisDriver != "" && $str_thisDriver != *"vfio-pci"* ]]; then
            if [[ $str_thisDriver == *"i915"* ]]; then
                bool_matchGivenIntelDriver=true
                break

            else
                bool_matchGivenIntelDriver=false
            fi
        fi
    done

# NOTE: incomplete
# check for newer intel driver #
#     if [[ $bool_matchGivenIntelDriver == true ]]; then
#         case [[ true ]]:

#             # NOTE: I do not believe this is accurate.
#             #       Commented out for now.
#             # bool_matchDistroArch:
#             #     if [[ $(yum list installed xserver-xorg-core xserver-xorg-video-modesetting )]]; then
#             #         bool_matchGivenIntelDriver=true

#             #     else
#             #         bool_matchGivenIntelDriver=false
#             #     fi

#             #     break;;

#             bool_matchDistroDebian:
#                 if [[ $(dpkg -l | grep -E 'xserver-xorg-core|xserver-xorg-video-modesetting') || $(apt list --installed xserver-xorg-core server-xorg-video-modesetting )]]; then
#                     bool_matchGivenIntelDriver=true

#                 else
#                     bool_matchGivenIntelDriver=false
#                 fi

#                 break;;

#             # NOTE: I do not believe this is accurate.
#             #       Commented out for now.
#             bool_matchDistroRedhat:
#                 if [[ $(dnf installed xserver-xorg-core xserver-xorg-video-modesetting) || $(yum installed xserver-xorg-core xserver-xorg-video-modesetting) ]]; then
#                     bool_matchGivenIntelDriver=true

#                 else
#                     bool_matchGivenIntelDriver=false
#                 fi

#                 break;;
#         esac
#     fi

# find first/last valid VGA driver #
    for str_thisBusID in ${arr_busID}; do

        # parameters #
        str_thisDriver=$(lspci -ks $str_thisBusID | grep -E 'driver')
        str_thisType=$(lspci -ms $str_thisBusID | cut -d '"' -f2 | tr '[:upper:]' '[:lower:]')
        str_thisVendor=$(lspci -ms $str_thisBusID | cut -d '"' -f4 | tr '[:upper:]' '[:lower:]')
        str_thisSlotID=$(echo $str_thisBusID | cut -d '.' -f1 )
        str_thisFuncID$(echo $str_thisBusID | cut -d '.' -f2 )

        # truncate zero digit of string #
        if [[ ${str_thisSlotID::1} == "0" ]]; then
            str_thisSlotID${str_thisSlotID::2}
        fi

        # rearrange string for Xorg output #
        str_thisBusID=$(echo ${str_thisBusID} | cut -d ':' -f1 )":"${str_thisSlotID}"."${str_thisFuncID}

        echo -e "Found Bus ID: '$str_thisBusID'"

        # match valid VGA device and driver #
        if [[ ($str_thisVendor == *"vga"* || $str_thisVendor == *"graphics" ) && ( -e $str_thisDriver || $str_thisDriver != "" ) && $str_thisDriver != *"vfio-pci"* ]]; then

            echo -e "Found Driver: '$str_thisDriver'"

            if [[ $str_thisVendor == "*intel"* ]]; then
                echo -e "WARNING: Should given parsed Intel VGA driver be invalid, replace xorg.conf with an alternate intel driver (example: 'modesetting')."
            fi

            # if [[ $str_thisVendor == "*intel"* && $bool_matchGivenIntelDriver == true ]]; then
            #     str_thisDriver="modesetting"
            # fi

            readonly str_thisBusID
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
\nSection \"Device\"
Identifier     \"Device0\"
Driver         \"$str_thisDriver\"
BusID          \"PCI:$str_thisBusID\"
EndSection")

            # append file #
            for str_line1 in ${arr_output1[@]}; do
                echo -e $str_line1 >> $str_outFile1
            done

            # # find display manager #
            # str_DM=`cat /etc/X11/default-display-manager`
            # str_DM=${str_DM:9:(${#str_DM}-9)}
            # str_DM=`echo $str_DM | tr '[:upper:]' '[:lower:]'`

            # # restart service #
            # str_input1=`echo $1 | tr '[:upper:]' '[:lower:]'`

            # if [[ $str_input1 == "dm"* && -e $str_DM ]]; then
            #     sudo systemctl enable $str_DM
            #     sudo systemctl restart $str_DM
            # fi

            # if [[ $str_input1 != "dm"* && -e $str_DM ]]; then
            #     echo -e "$0: You may restart the active display manager ($str_DM).\n$0: Execute 'systemctl restart $str_DM'."
            # fi

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
\n#Section \"Device\"
#Identifier     \"Device0\"
#Driver         \"driver_name\"
#BusID          \"PCI:x:x:x\"
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
