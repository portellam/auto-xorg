#!usr/bin/env bash

## FUNCTION ##
# NOTES:
# -script is NOT working at the moment!
#
# DESCRIPTION:
# -function sets current xorg display device by finding the first VGA device WITHOUT the kernel driver 'vfio-pci'.
# -function is to be run at boot by ROOT/SUDO.
#
# STEPS:
# -save logfile of lspci
# -read from lspci logfile
# -save output from two lines, first line and third line.
# -if current line begins with an IOMMU ID... (example: '01:00.0 VGA compatible controller'...), then set counter integer to 0 and begin increments.
# -check first line PCI is VGA (example: '01:00.0 VGA compatible controller'...), then save IOMMU ID (example: '01:00.0'), and continue to third line.
# -check third line for kernel driver (example: 'Kernel driver in use: vfio-pci'), if NOT 'vfio-pci', then save kernel driver, and exit.
# -delete logfile
##

# datetime #
datetime="#`date +%Y-%m-%d_%H:%M:%S`"
#

# logfile #
lspci -nnk > /var/log/lspci.log
file='/var/log/lspci.log'
#

#
while IFS= read -r line; do
    # variables
    read line
    echo $line                              # DEBUG
    count=0
    bool_one=false
    bool_three=false
    str_one=${line:10:8}
    str_three=${line:21:0}
    
    # begin line one.
    if $str_one -eq "VGA"; then
        ((bool_one=true))
    fi 
    if $bool_one; then
        echo $line                          # DEBUG
        PCI_ID=${line:6:1}                  # EXAMPLE: '01:00.0 VGA'    => '01:00.0'
        echo $PCI_ID                        # DEBUG
        sub1=${PCI_ID:6:5}+:${PCI_ID:6:6}   # EXAMPLE: '01:00.0'        => '01:00:0'
        echo $sub1                          # DEBUG
        sub2=${sub1:2:0}+${sub2:6:4}        # EXAMPLE: '01:00:0'        => '01:0:0'
        echo $sub2                          # DEBUG
        newPCI_ID=${sub2:5:1}               # EXAMPLE: '01:0:0'         => '1:0:0'
        echo $newPCI_ID                     # DEBUG
        # move on to line three.
        ((bool_one=false))
    fi
    # end of line one.
    
    # begin line three
    if $str_three -eq 'Kernel driver in use: '; then
        ((bool_three=true))
    fi
    if $bool_three; then
        echo $line                          # DEBUG
        kernel_driver=${line:${#line}:21}
        echo $kernel_driver                 # DEBUG
        # if current kernel driver is vfio-pci, then go back to line one.
        if $kernel_driver -eq 'vfio-pci'; then
            ((bool_three=false))        
        # if current kernel driver is NOT vfio-pci...
        else
            echo "'/etc/X11/xorg.conf.d/': set all VGA kernel driver files to NOT readable (0200)."     
            # set all XORG conf's of VGA kernel drivers to NOT readable.
            chmod 200 /etc/X11/xorg.conf.d/10-*.conf    
            # check if current VGA kernel driver's XORG conf exists.
            if -f "/etc/X11/xorg.conf.d/10-$kernel_driver"; then
                echo "'/etc/X11/xorg.conf.d/10-$kernel_driver': file exists."
            # if NOT, create one.
            else
                echo "'/etc/X11/xorg.conf.d/10-$kernel_driver': file does NOT exist. Creating file..."
                cat > /etc/X11/xorg.conf.d/10-$kernel_driver.conf < EOF
datetime
Section "Device"
Identifier     "Device0"
Driver         "$kernel_driver"
BusID          "PCI:$PCI_ID"
EndSection
EOF
            fi
            # then set to executable.
            echo "'/etc/X11/xorg.conf.d/10-$kernel_driver': set file to readable (0644)."
            chmod 644 /etc/X11/xorg.conf.d/10-$kernel_driver.conf
            # then restart display manager (?).
            #systemctl restart lightdm sddm
            break
        fi
    fi
    # end of line three.
done
#

# delete logfile #
rm $file
#
exit 0
