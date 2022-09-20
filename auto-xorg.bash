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
    for str_thisPCI_ID in ${arr_PCI_ID}; do

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
    for str_thisPCI_ID in ${arr_PCI_ID}; do

        # parameters #
        str_thisDriver=$(lspci -ks $str_thisPCI_ID | grep -E 'driver' | cut -d ':' -f2 | cut -d ' ' -f2)
        str_thisType=$(lspci -ms $str_thisPCI_ID | cut -d '"' -f2 | tr '[:upper:]' '[:lower:]')
        str_thisVendor=$(lspci -ms $str_thisPCI_ID | cut -d '"' -f4 | tr '[:upper:]' '[:lower:]')
        str_thisBusID=$(echo $str_thisPCI_ID | cut -d ':' -f1 )
        str_thisSlotID=$(echo $str_thisPCI_ID | cut -d ':' -f2 | cut -d '.' -f1 )
        str_thisFuncID$(echo $str_thisPCI_ID | cut -d '.' -f2 )

        # truncate zero digit of string #
        if [[ ${str_thisBusID::1} == "0" ]]; then
            str_thisBusID${str_thisBusID::2}
        fi

        if [[ ${str_thisSlotID::1} == "0" ]]; then
            str_thisSlotID${str_thisSlotID::2}
        fi

        # rearrange string for Xorg output #
        str_thisPCI_ID=${str_thisBusID}":"${str_thisSlotID}"."${str_thisFuncID}

        echo -e "Found Bus ID: '$str_thisPCI_ID'"

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
Identifier\t\"Device0\"
Driver\t\t\"$str_thisDriver\"
BusID\t\t\"PCI:$str_thisPCI_ID\"
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
\n#Section\t\"Device\"
#Identifier\t\"Device0\"
#Driver\t\t\"driver_name\"
#BusID\t\t\"PCI:x:x:x\"
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
