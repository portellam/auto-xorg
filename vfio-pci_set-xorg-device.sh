#!/bin/bash

## FUNCTION ##
# NOTES:
# -script is NOT working at the moment!
#
# DESCRIPTION:
# -function sets current xorg display device by finding the first VGA device WITHOUT the kernel driver 'vfio-pci'.
# -function is to be run (at boot) by root or sudo.
#
# STEPS:
# -save logfile of lspci
# -read from lspci logfile
# -save output from two lines, first line and third line.
# -if current line begins with an IOMMU ID... (example: '01:00.0 VGA compatible controller'...), then set counter integer to 0 and begin increments.
# -check first line PCI is VGA (example: '01:00.0 VGA compatible controller'...), then save IOMMU ID (example: '01:00.0'), and continue to third line.
# -check third line for kernel driver (example: 'Kernel driver in use: vfio-pci'), if NOT 'vfio-pci', then save kernel driver, and exit.
# OPTIONAL: -restart display manager
# -delete logfile
##

## PARAMETERS ##
bool=false

## FUNCTIONS ##
new_logfile () {
    lspci -nnk > /var/log/lscpi.log
    return /var/log/lspci.log
}

find_line () {
    while IFS= read -r line
    do
        echo $line              # DEBUG
        if [ ${line:8:3} -eq "VGA" ]
        then
            PCI_ID=${line:1:5}                  # EXAMPLE: '01:00.0 VGA'    => '01:00.0'
            echo "$PCI_ID"      # DEBUG
            sub1=${PCI_ID:5:2}+:${PCI_ID:6:1}   # EXAMPLE: '01:00.0'        => '01:00:0'
            echo "$sub1"        # DEBUG
            sub2=${sub1:0:3}+${sub2:4:3}        # EXAMPLE: '01:00:0'        => '01:0:0'
            echo "$sub2"        # DEBUG
            newPCI_ID=${sub2:1:6}               # EXAMPLE: '01:0:0'         => '1:0:0'
            echo "$newPCI_ID"   # DEBUG
        fi
        if [ ${line:0:22}="Kernel driver in use: " ]
        then
            n=${#line}-21
            kernel_driver=${line:21:n}
            echo $kernel_driver # DEBUG
            if [ $kernel_driver -ne "vfio-pci" ]
            then
                ((bool=true))
                break
            fi
        fi
    done
}

setup_xorg() {
    echo "'/etc/X11/xorg.conf.d/': set all VGA kernel driver files to NOT readable (0200)."
    chmod 200 /etc/X11/xorg.conf.d/10-*.conf    # set all XORG conf's of VGA kernel drivers to NOT readable.
    if [ -f "/etc/X11/xorg.conf.d/10-$kernel_driver" ] # check if current VGA kernel driver's XORG conf exists.
    then
        echo "'/etc/X11/xorg.conf.d/10-$kernel_driver': file exists."
        else    # if NOT, create one.
        echo "'/etc/X11/xorg.conf.d/10-$kernel_driver': file does NOT exist. Creating file..."
        cat > /etc/X11/xorg.conf.d/10-$kernel_driver.conf < EOF
Section "Device"
Identifier     "Device0"
Driver         "$kernel_driver"
BusID          "PCI:$PCI_ID"
EndSection
EOF
    fi
    echo "'/etc/X11/xorg.conf.d/10-$kernel_driver': set file to readable (0644)."   # then set to executable.
    chmod 644 /etc/X11/xorg.conf.d/10-$kernel_driver.conf
}

restart_dm () {
    cat /etc/X11/default-display-manager > $line # find primary display manager
    echo $line  # DEBUG
    dm=${line:8:(${#line}-9)}
    echo $dm    # DEBUG
    systemctl restart $dm # restart display manager
}
##

## MAIN ##
new_logfile ()
find_line ()
if [ bool ]
then
    setup_xorg ()
fi
#restart_dm ()
rm $file
exit 0
##
