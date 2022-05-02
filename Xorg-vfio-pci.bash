#!/bin/bash

## METHODS start ##

function 01_FindPCI {
    
    echo "FindPCI: Start."

    # CREATE LOG FILE #
    str_dir="/var/log/"
    str_file_1=$str_file'lspci_n.log'
    str_file_2=$str_file'lspci.log'
    str_file_3=$str_file'lspci_k.log'
    lspci -n > $str_file_1
    lspci > $str_file_2
    lspci -k > $str_file_3
    #

    ## BOOLEANS ##
    bool_beginParsePCI=false
    bool_beginParseThisPCI=false
    #

    # COUNTER #
    declare -i int_count=1
    #

    # PCI #
    str_first_PCIbusID="1:00.0"
    str_PCIbusID=""
    str_PCIdriver=""
    str_PCIhwID=""
    str_PCItype=""
    str_xorg_PCIbusID=""
    str_xorg_PCIdriver=""
    declare -a arr_PCIbusID
    declare -a arr_PCIdriver
    declare -a arr_PCIhwID
    declare -a arr_int_indexOfVGA
    #

    # FILE_1 #
    # PARSE FILE, SAVE PCI BUS ID AND PCI HW ID TO ARRAYS
    while read str_line_1; do
        
        str_PCIbusID=${str_line_1:1:6}
        echo "PCI: str_PCIbusID: \"$str_PCIbusID\""

        # START READ FROM FIRST EXTERNAL PCI
        if [[ $str_PCIbusID == $str_first_PCIbusID ]]; then
                
            bool_beginParsePCI=true

        fi
        
        # SAVE PCI HARDWARE ID
        if [[ $bool_beginParsePCI == true ]]; then

            arr_PCIbusID+=("$str_PCIbusID")
            echo "PCI: str_PCIbusID: \"$str_PCIbusID\""

            str_PCIhwID=$( echo ${str_line_1:14:9} )
            arr_PCIhwID+=("$str_PCIhwID")
            echo "PCI: str_PCIhwID: \"$str_PCIhwID\""

        fi

    done < $str_file_1
    # FILE 1 END #

    # FILE 2 #
    # PARSE FILE, CHECK IF PCI DEVICE IS VGA AND SAVE INDEX TO ARRAY
    while read str_line_2; do

        # PARSE ARRAY
        for str_arr_PCIbusID in "${arr_PCIbusID[@]}"; do

            echo "PCI: str_arr_PCIbusID: \"$str_arr_PCIbusID\""

            # VALIDATE PCI BUS ID
            if [[ $str_arr_PCIbusID == ${str_line_2:1:6} ]]; then

                echo "PCI: str_arr_PCIbusID: \"$str_arr_PCIbusID\""

                #str_VGA_PCIbusID=$str_arr_PCIbusID        

                str_PCItype=${str_line_2:8:3}

                # CHECK IF PCI IS VGA
                if [[ ${str_line_2:8:3} == "VGA" ]]; then

                    arr_int_indexOfVGA+=("$int_count")
                    echo "PCI: Found VGA device at $str_arr_PCIbusID"

                fi

                echo "PCI: int_count:\"$int_count\""
                (($int_count++))
                echo "PCI: int_count:\"$int_count\""

            fi
        
        done

    done < $str_file_2
    # FILE 2 END #  

    # FILE 3 #
    # PARSE FILE, SAVE EACH DRIVER FOR VFIO SETUP, AND CHECK IF INDEXED VGA DEVICE IS NOT GRABBED BY VFIO-PCI DRIVER AND SAVE VGA DEVICE PCI BUS ID, HW ID, AND DRIVER FOR XORG SETUP
    while $read str_line_3; do

        # PARSE THIS PCI DEVICE
        while [[ $bool_beginParseThisPCI == false ]]; do
        
            # PARSE ARRAY
            for int_indexOfVGA in "${arr_int_indexOfVGA[@]}"; do

                str_thisPCIbusID=$arr_PCIbusID[$arr_int_indexOfVGA]
                echo "PCI: str_thisPCIbusID: \"$str_thisPCIbusID\""

                if [[ $arr_PCIbusID[$arr_int_indexOfVGA] == ${str_line_3:1:6} && $str_line_3 != *"Kernel driver in use: "* && $str_line_3 != *"Subsystem: "* && $str_line_3 != *"Kernel modules: "* ]]; then

                    bool_beginParseThisPCI=true
                    echo "PCI: bool_beginParseThisPCI: \"$bool_beginParseThisPCI\""

                fi

            done

        done

        # VALIDATE STRING FOR PCI DRIVER
        if [[ $str_line_3 == *"Kernel driver in use: "* && $str_line_3 != *"Subsystem: "* && $str_line_3 != *"Kernel modules: "* ]]; then
                                                                    
            int_len_str_line_3=${#str_line_3}-22
            str_PCIdriver=${str_line_3:22:$int_len_str_line_3}
            echo "PCI: str_PCIdriver: \"$str_PCIdriver\""
            

            # SAVE EACH VALID PCI DRIVER
            # NOTE: RUN SCRIPT ONCE TO HAVE ALL EXTERNAL PCI DEVICE ADDED TO VFIO-PCI
            if [[ $str_PCIdriver != "vfio-pci" ]]; then

                arr_PCIdriver+=("$str_PCIdriver")

                # SAVE THIS PCI DEVICE IF NOT GRABBED BY VFIO-PCI DRIVER
                if [[ $bool_beginParseThisPCI == true ]]; then
                
                    str_xorg_PCIbusID=$str_thisPCIbusID
                    echo "PCI: str_xorg_PCIbusID: \"$str_xorg_PCIbusID\""
                    str_xorg_PCIdriver=$str_PCIdriver
                    echo "PCI: str_xorg_PCIdriver: \"$str_xorg_PCIdriver\""
                    bool_beginParseThisPCI=false
                    echo "PCI: bool_beginParseThisPCI: \"$bool_beginParseThisPCI\""

                fi

            fi

        fi
        
    done < $str_file_3
    # FILE 3 END #
            
    # CLEAR LOG FILES
    rm $str_file_1 $str_file_2 $str_file_3
        
    echo "FindPCI: End."
    
}

function 02_Xorg {

    echo "Xorg: Start."

    # SET WORKING DIRECTORY
    str_dir="/etc/X11/xorg.conf.d/"

    # INIT FILE
    str_file=$str_dir"10-"$str_xorg_PCIdriver".conf"
    
    # CLEAR FILES
    rm $str_dir"10-"*".conf"
    
    # PARAMETERS
    declare -a arr_Xorg=(
"Section "Device"
Identifier     "Device0"
Driver         "$str_xorg_PCIdriver"
BusID          "PCI:$str_xorg_PCIbusID"
EndSection
"
)

    # ARRAY LENGTH
    int_sources=${#arr_sources[@]}
    
    # WRITE ARRAY TO FILE
    for (( int_index=0; int_index<$int_sources; int_index++ )); do
    
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

# METHODS #
01_FindPCI
#02_Xorg
#

echo "MAIN: End."

## MAIN end ##

exit 0
