#!/bin/bash

# NOTE: run as 'sudo bash script.sh'

## FUNCTION ##
#
# DESCRIPTION:
# -function sets current xorg display device by finding the first VGA device WITHOUT the kernel driver 'vfio-pci'.
# -function is to be run (at boot) by root or sudo.
#
# STEPS:
# -save logfile of lspci
# -read from lspci logfile
# -save output from two lines, first line and third line.
# -check first line PCI is VGA (EXAMPLE: '01:00.0 VGA compatible controller'...), then save IOMMU ID (example: '01:00.0'), and continue to third line.
# -check third line for kernel driver (EXAMPLE: 'Kernel driver in use: vfio-pci'). If 'vfio-pci' save as commented file. If a valid driver, save as file.
# -delete logfile
#
##

## INIT ##
rm -rf /etc/X11/xorg.conf.d/10-*.conf
boolLoop=true
boolDrv=false
boolVfio=false

## FUNCTIONS ##
function new_logfile {
    lspci -nnk > /var/log/lscpi.log
    strFile="/var/log/lspci.log"
}

function find_line {
    while IFS= read -r strLine
    do
        #echo $strLine                                                   # DEBUG
        if [[ strLine -eq null ]]
            echo "'$strFile': End of file."
            ((boolLoop=false))
            break
        fi
        if [[ ${strLine:8:3} -eq "VGA" ]]
        then
            strPciID=${strLine:1:5}                                     # EXAMPLE: '01:00.0 VGA'    => '01:00.0'
            strSub1=${strPciID:5:2}+:${strPciID:6:1}                    # EXAMPLE: '01:00.0'        => '01:00:0'
            #echo "$strSub1"                                             # DEBUG
            strSub2=${strSub1:0:3}+${strSub2:4:3}                       # EXAMPLE: '01:00:0'        => '01:0:0'
            #echo "$strSub2"                                             # DEBUG
            strNewPciID=${strSub2:1:6}                                  # EXAMPLE: '01:0:0'         => '1:0:0'
            #echo "$strNewPciID"                                         # DEBUG
        else
            echo "Line 1: False match. Skipping."
        fi
        if [[ ${strLine:0:22}="Kernel driver in use: " ]]
        then
            n=${#strLine}-21
            strDrv=${strLine:21:n}
            echo $strDrv # DEBUG
            if [[ $strDrv -ne "vfio-pci" ]]
            then
                ((boolVfio=true))
                ((boolDrv=false))
                break
            else
                ((boolDrv=true))
                ((boolVfio=false))
            fi
        else
            echo "Line 3: False match. Skipping."
        fi
    done < $strFile
}

function setup_xorg {
    if [[ $boolDrv || $boolVfio ]]
    then
        if $boolDrv
        then
            cat > /etc/X11/xorg.conf.d/10-$strDrv.conf < EOF            # EXAMPLE: "Kernel driver in use: nouveau"
Section "Device"
Identifier     "Device0"
Driver         "$strDrv"
BusID          "PCI:$strPciID"
EndSection
EOF
        fi
        # NOTE: not usable #
        #
        #if $boolVfio
        #then
            #cat > /etc/X11/xorg.conf.d/10-$strDrv.conf < EOF            # EXAMPLE: "Kernel driver in use: vfio-pci"
#Section "Device"
#Identifier     "Device0"
#Driver         "$strDrv"
#BusID          "PCI:$strPciID"
#EndSection
#EOF
        #fi
        #
    fi
    # reset booleans.
    ((boolDrv=false))
    ((boolVfio=false))
}

function restart_dm {
    cat /etc/X11/default-display-manager > $strLine                     # find primary display manager
    #echo $strLine                                                       # DEBUG
    strDM=${strLine:8:(${#strLine}-9)}
    #echo $strDM                                                         # DEBUG
    systemctl restart $strDM                                            # restart display manager
}
##

## MAIN ##
new_logfile
while $boolLoop
do
    find_line
    setup_xorg
done
#restart_dm
#rm $strFile
exit 0
##
