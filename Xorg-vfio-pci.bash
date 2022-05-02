#!/bin/bash

## METHODS start ##

function 01_FindPCI {
    
    echo "FindPCI: Start."

    ## PARAMETERS ##
    declarebool_read=false
    bool_matchPCIbusID=false
    bool_matchVGA=false
    bool_matchPCIdriver=false
    declare -i int_count=1
    # CREATE LOG FILE #
    str_dir="/var/log/"
    str_file_1=$str_file'lspci_n.log'
    str_file_2=$str_file'lspci.log'
    str_file_3=$str_file'lspci_k.log'
    lspci -n > $str_file_1
    lspci > $str_file_2
    lspci -k > $str_file_3
    #
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
    
    # FILE_1 #
    # PARSE FILE AND SAVE TO ARRAY
    while read str_line_1; do
        
        str_PCIbusID=${str_line_1:1:6}

        # START READ FROM FIRST EXTERNAL PCI
        if [[ $str_PCIbusID == $str_first_PCIbusID ]]; then
                
            bool_read=true

        fi
        
        # SAVE PCI HARDWARE ID
        if [[ $bool_read == true ]]; then
        
            str_PCIhwID=$( echo ${str_line_1:14:9} )
            #echo "PCI: str_PCIhwID: \"$str_PCIhwID\""
            arr_PCIbusID+=("$str_PCIbusID")

        fi

    done < $str_file_1
    # FILE 1 END #

    # FILE 2 #
    # PARSE FILE AND CHECK FOR VGA MATCH
    while read str_line_2; do

        # PARSE ARRAY
        for str_arr_PCIbusID in "${arr_PCIbusID[@]}"; do

            #echo "PCI: str_arr_PCIbusID: \"$str_arr_PCIbusID\""
            #echo "PCI: {str_line_2:1:6}: \"${str_line_2:1:6}\""

            # VALIDATE PCI BUS ID
            if [[ $str_arr_PCIbusID == ${str_line_2:1:6} ]]; then
                           
                bool_matchPCIbusID=true
                #echo "PCI: bool_matchPCIbusID: \"$bool_matchPCIbusID\""
                str_PCItype=${str_line_2:8:3}
                echo "PCI: str_PCItype: \"$str_PCItype\""

                # CHECK IF PCI IS VGA
                if [[ $str_PCItype == "VGA" ]]; then

                    bool_matchVGA=true
                    echo "PCI: bool_matchVGA: \"$bool_matchVGA\""
                
                else

                    bool_matchVGA=false

                fi

            fi
        
        done

    done < $str_file_2
    # FILE 2 END #  


    # FILE 3 #
    # PARSE FILE, CHECK FOR PCI MATCH, SAVE EACH PCI VGA BUS ID, NON VFIO-PCI VGA DRIVER
    while read str_line_3; do  
        
        # VALIDATE STRING FOR PCI TYPE
        if [[ $bool_matchPCIbusID == true && $str_line_3 != *"Kernel driver in use: "* && $str_line_3 != *"Subsystem: "* && $str_line_3 != *"Kernel modules: "* ]]; then

            str_PCItype=${str_line_3:8:3}
            #echo "PCI: str_PCItype: \"$str_PCItype\""

            # CHECK IF PCI IS VGA
            if [[ $str_PCItype == "VGA" ]]; then

                bool_matchVGA=true
                #echo "PCI: bool_matchVGA: \"$bool_matchVGA\""
                
            else

                bool_matchVGA=false

            fi

        fi

        # VALIDATE STRING FOR PCI DRIVER
        if [[ $bool_matchVGA == true && $str_line_3 == *"Kernel driver in use: "* && $str_line_3 != *"Subsystem: "* && $str_line_3 != *"Kernel modules: "* ]]; then
                                                                    
            int_len_str_line_3=${#str_line_3}-22
            str_PCIdriver=${str_line_3:22:$int_len_str_line_3}
            echo "PCI: str_PCIdriver: \"$str_PCIdriver\""
            bool_matchPCIdriver=true
            echo "PCI: bool_matchPCIdriver: \"$bool_matchPCIdriver\""

        fi

        # SAVE FIRST EXTERNAL VGA NON VFIO-PCI DEVICE
        if [[ $bool_matchPCIdriver == true && $str_PCIdriver != "vfio-pci" ]]; then
                                    
            str_xorg_PCIbusID=$str_PCIbusID
            str_xorg_PCIdriver=$str_PCIdriver
            echo "PCI: str_xorg_PCIbusID: \"$str_xorg_PCIbusID\""
            echo "PCI: str_xorg_PCIdriver: \"$str_xorg_PCIdriver\""
            break                        

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

# SHARED PARAMETERS #
#str_xorg_PCIbusID=""
#str_xorg_PCIdriver=""
declare -a arr_PCIdriver=()
declare -a arr_PCIhwID=()
#

# METHODS #
01_FindPCI
echo "MAIN: str_xorg_PCIbusID: \"$str_xorg_PCIbusID\""
echo "MAIN: str_xorg_PCIdriver: \"$str_xorg_PCIdriver\""
#02_Xorg
#

echo "MAIN: End."

## MAIN end ##

exit 0
