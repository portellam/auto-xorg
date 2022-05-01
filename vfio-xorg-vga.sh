#!/bin/bash

## METHODS start ##

function 0A_FindVGA {

    echo "PCI: Start."

    # PARAMETERS
    str_first_PCIbusID="01.00.0"
    str_PCI_type=""
    bool_beginParse=false

    # CREATE LOG FILE
    str_file="/var/log/lspci.log"

    if [ -e $str_file ] ; then
        rm $str_file
    fi
    lspci -nnk > $str_file

    # CREATE DEBUG LOG FILE
    cd /home/user
    str_file2="lspci.log.txt"
    if [ -e $str_file2 ] ; then
        rm $str_file2
    fi
    lspci -nnk > $str_file2
    
    # PARSE LOG FILE
    while read str_line; do

        # PARAMETERS
        str_PCIbusID=(${str_line:0:7})    # EXAMPLE: "01:00.0"
        #echo "PCI: str_PCIbusID: \"$str_PCIbusID\""
        
        # RUN ONCE: ASSUME CURRENT LINE IS LINE ONE, IF PCI BUS ID IS FIRST PCI CARD, AND BOOL IS FALSE
        if [[ $str_PCIbusID=$str_first_PCIbusID && $bool_beginParse=false ]]; then
                    
            # EXIT STATEMENT, AND NEVER RUN AGAIN
            bool_beginParse=true
            
        fi
        
        # GRAB PCI TYPE # EXAMPLE: "VGA" "Audio" "USB" etc.
        # SUBSTRING RANGE IS FIRST CHAR OF PCI TYPE WITH LENGTH OF ARBITRARY INTEGER
        str_PCI_type=$(echo ${str_line:8:50} | cut -d " " -f1)    # EXAMPLE: "VGA compatible controller..."
        #echo "PCI: str_PCI_type: \"$str_PCI_type\""
        
        
        if $bool_beginParse; then
        
            # IGNORED LINES
            if [[ $str_line=*'DeviceName: '* || $str_line=*'Subsystem: '* || $str_line=*'Kernel modules: '* ]]; then
        
                echo "PCI: No match found."
            
            # FIND KERNEL DRIVER
            else if [[ $str_line=*'Kernel driver in use: '* ]]; then
        
                    echo "PCI: Kernel driver: Found device."
                
                    # IF DEVICE IS VGA, AND FIRST VGA DEVICE IS NOT FOUND...
                    if [[ $str_PCI_type="VGA" ]]; then
        
                        echo "PCI: Kernel driver: Found VGA device."
                    
                        int_n=${#str_line}-22
                        str_PCIdriver=${str_line:22:$int_n}
                
                        # IF NOT GRABBED BY VFIO-PCI...
                        if [[ $str_PCIdriver -ne "vfio-pci" ]]; then
                         
                            # SAVE STRINGS FOR XORG FILE
                            str_firstVGA_PCIbusID=$str_PCIbusID
                            str_firstVGA_PCIdriver=$str_PCIdriver
                        
                            # DEBUG
                            echo "PCI: PCI Bus ID: '$str_firstVGA_PCIbusID'"    # DEBUG
                            echo "PCI: PCI driver: '$str_firstVGA_PCIdriver'"   # DEBUG
                    
                            # EXIT FUNCTION
                            break
                
                        fi
                
                        # DEBUG
                        echo "PCI: PCI Bus ID: '$str_PCIbusID'"     # DEBUG
                        echo "PCI: PCI driver: '$str_PCIdriver'"    # DEBUG
                
                    fi
                 
                else
                
                    # FIND PCI BUS ID
                    # TODO: FIND PCI HW ID, eight-char in two brackets, second set of brackets
                    if [[ ${str_line:8:3}="VGA" ]]; then
            
                        echo "PCI: str_PCIbusID: \"$str_PCIbusID\""
                        str_PCIbusID="${str_line:1:5}"                          # EXPECT: '01:00.0'
                        echo "PCI: str_PCIbusID: \"$str_PCIbusID\""
                        str_PCIbusID="${str_PCIbusID:5:2}:${str_PCIbusID:6:1}"  # EXPECT: '01:00:0'
                        echo "PCI: str_PCIbusID: \"$str_PCIbusID\""
                        str_PCIbusID="${str_PCIbusID:0:3}${str_PCIbusID:4:3}"   # EXPECT: '01:0:0'
                        echo "PCI: str_PCIbusID: \"$str_PCIbusID\""
                        str_PCIbusID="${str_PCIbusID:1:6}"                      # EXPECT: '1:0:0'
                        echo "PCI: str_PCIbusID: \"$str_PCIbusID\""
        
                    fi
                
                fi
                
            fi
        
        fi
    
    done < $str_file

    # CLEAR LOG FILE
    rm $str_file
    
    echo "PCI: End."

}

function 0B_Xorg {

    echo "Xorg: Start."

    # SET WORKING DIRECTORY
    str_dir="/etc/X11/xorg.conf.d/"

    # SET FILE
    str_file=$str_dir'10-'$str_firstVGA_PCIdriver'.conf'
    
    # CLEAR FILES
    rm $str_dir'10-'*
    
    # PARAMETERS
    declare -a arr_Xorg=(
"Section "Device"
Identifier     "Device0"
Driver         "$str_firstVGA_PCIbusID"
BusID          "PCI:$str_firstVGA_PCIdriver"
EndSection
"
)

    int_line=${#arr_sources[@]}
    for (( int_index=0; int_index<$int_line; int_index++ )); do
        str_line=${arr_Xorg[$int_index]}
        echo $str_line >> $str_file
    done

    # FIND PRIMARY DISPLAY MANAGER
    #$str_line=$(cat /etc/X11/default-display-manager)
    #str_DM=${str_line:8:(${#str_line}-9)}

    # RESTART DM
    #systemctl restart $str_DM

    echo "Xorg: End."

}

## METHODS end ##

## MAIN start ##

echo "MAIN: Start."

# PARAMETERS #
str_line_PCI_type=""

# METHODS #
0A_FindVGA
#0B_Xorg

echo "MAIN: End."

## MAIN end ##

exit 0
