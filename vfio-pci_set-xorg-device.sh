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
boolDrv=false
boolVGA=false

## FUNCTIONS ##
function newLogFile {
    lspci -nnk > /var/log/lscpi.log
    strFile="/var/log/lspci.log"
}

function findLine {
    while IFS= read -r strLine
    do
        echo "Line 1: strLine: '$strLine'"                              # DEBUG
        if [[ -z $strLine ]]
        then
            echo "'$strFile': End of file."
            break
        fi
        if [[ ! $boolVGA && ${strLine:8:3}="VGA" ]]
        then
            strPciID=${strLine:1:5}                                     # EXAMPLE: '01:00.0 VGA'    => '01:00.0'
            strSub1=${strPciID:5:2}+:${strPciID:6:1}                    # EXAMPLE: '01:00.0'        => '01:00:0'
            strSub2=${strSub1:0:3}+${strSub2:4:3}                       # EXAMPLE: '01:00:0'        => '01:0:0'
            strNewPciID=${strSub2:1:6}                                  # EXAMPLE: '01:0:0'         => '1:0:0'
            echo "Line 1: {strLine:8:3}: '${strLine:8:3}'"              # DEBUG
            echo "Line 1: strSub1: '$strSub1'"                          # DEBUG
            echo "Line 1: strSub2: '$strSub2'"                          # DEBUG
            echo "Line 1: strNewPciID: '$strNewPciID'"                  # DEBUG
            ((boolVGA=true))
        else
            echo "Line 1: False match. Skipping."
        fi
        if [[ $boolVGA && ${strLine:0:23}="Kernel driver in use: " ]]
        then
            echo "Line 3: ${strLine:0:23}: '${strLine:0:23}'"           # DEBUG
            n=${#strLine}-23
            strDrv=${strLine:23:n}
            if [[ $strDrv -ne "vfio-pci" ]]
            then
                ((boolDrv=true))
                echo "Driver found: '$strDrv'"                          # DEBUG
                break
            fi
        else
            echo "Line 3: False match. Skipping."
        fi
    done < $strFile
}

function setupXorg {
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
    echo "'$strDrv': End of file."
}

function restartDM {
    cat /etc/X11/default-display-manager > $strLine                     # find primary display manager
    echo "'/etc/X11/default-display-manager': strLine: '$strLine'"      # DEBUG
    strDM=${strLine:8:(${#strLine}-9)}
    echo "strDM: '$strDM'"                                              # DEBUG
    systemctl restart $strDM                                            # restart display manager
}
##

## MAIN ##
newLogFile ()
findLine ()
setupXorg ()
#restartDM ()
#rm $strFile
exit 0
##
