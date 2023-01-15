#!/bin/bash

#
# Author(s):    Alex Portell <https://github.com/portellam>
# Description:  Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.
#

# <summary> #0 - Global parameters </summary>
# <params>
    declare -gl str_package_manager=""

    # <summary> Exit codes </summary>
    declare -gir int_code_var_is_null=255
    declare -gir int_code_var_is_empty=254
    declare -gir int_code_dir_is_null=253
    declare -gir int_code_file_is_null=252
    declare -gir int_code_var_is_NAN=251
    declare -gir int_code_cmd_is_null=251
    declare -gi int_exit_code="$?"

    # <summary>
    # Color coding
    # Reference URL: 'https://www.shellhacks.com/bash-colors'
    # </summary>
    declare -gr var_blinking_red='\033[0;31;5m'
    declare -gr var_green='\033[0;32m'
    declare -gr var_red='\033[0;31m'
    declare -gr var_yellow='\033[0;33m'
    declare -gr var_reset='\033[0m'

    # <summary> Append output </summary>
    declare -gr var_prefix_error="${var_yellow}Error:${var_reset}"
    declare -gr var_prefix_fail="${var_red}Failure:${var_reset}"
    declare -gr var_prefix_pass="${var_green}Success:${var_reset}"
    declare -gr var_prefix_warn="${var_blinking_red}Warning:${var_reset}"
    declare -gr var_suffix_fail="${var_red}Failure${var_reset}"
    declare -gr var_suffix_pass="${var_green}Success${var_reset}"
    declare -gr str_output_var_is_not_valid="${var_prefix_error} Invalid input."
# </params>

# <summary> #2 - Data-type and variable validation </summary>
# <code>
    # <summary> Check if the command is installed. </summary>
    # <param name="$1"> the command </param>
    # <returns> exit code </returns>
    #
    function CheckIfCommandIsInstalled
    {
        # <params>
        local readonly str_output_cmd_is_null="${var_prefix_error} Command '$1' is not installed."
        local readonly var_actual_install_path=$( command -v $1 )
        local readonly var_expected_install_path="/usr/bin/$1"
        # </params>

        if ! CheckIfVarIsValid $1; then
            return $?
        fi

        # if $( ! CheckIfVarIsValid $var_actual_install_path ) &> /dev/null || [[ "${var_actual_install_path}" != "${var_expected_install_path}" ]]; then
        if $( ! CheckIfVarIsValid $var_actual_install_path ) &> /dev/null; then
            echo -e $str_output_cmd_is_null
            return $int_code_cmd_is_null
        fi

        return 0
    }

    # <summary> Check if the value is valid. </summary>
    # <param name="$1"> the value </param>
    # <returns> exit code </returns>
    #
    function CheckIfVarIsValid
    {
        # <params>
        local readonly str_output_var_is_null="${var_prefix_error} Null string."
        local readonly str_output_var_is_empty="${var_prefix_error} Empty string."
        # </params>

        if [[ -z "$1" ]]; then
            echo -e $str_output_var_is_null
            return $int_code_var_is_null
        fi

        if [[ "$1" == "" ]]; then
            echo -e $str_output_var_is_empty
            return $int_code_var_is_empty
        fi

        return 0
    }

    # <summary> Check if the value is a valid number. </summary>
    # <param name="$1"> the value </param>
    # <returns> exit code </returns>
    #
    function CheckIfVarIsNum
    {
        # <params>
        local readonly str_output_var_is_NAN="${var_prefix_error} NaN."
        local readonly str_num_regex='^[0-9]+$'
        # </params>

        if ! CheckIfVarIsValid $1; then
            return $?
        fi

        if ! [[ $1 =~ $str_num_regex ]]; then
            echo -e $str_output_var_is_NAN
            return $int_code_var_is_NAN
        fi

        return 0
    }

    # <summary> Check if the directory exists. </summary>
    # <param name="$1"> the value </param>
    # <returns> exit code </returns>
    #
    function CheckIfDirExists
    {
        # <params>
        local readonly str_output_dir_is_null="${var_prefix_error} Directory '$1' does not exist."
        # </params>

        if ! CheckIfVarIsValid $1; then
            return $?
        fi

        if [[ ! -d "$1" ]]; then
            echo -e $str_output_dir_is_null
            return $int_code_dir_is_null
        fi

        return 0
    }

    # <summary> Check if the file exists. </summary>
    # <param name="$1"> the value </param>
    # <returns> exit code </returns>
    #
    function CheckIfFileExists
    {
        # <params>
        local readonly str_output_file_is_null="${var_prefix_error} File '$1' does not exist."
        # </params>

        if ! CheckIfVarIsValid $1; then
            return $?
        fi

        if [[ ! -e "$1" ]]; then
            echo -e $str_output_file_is_null
            return $int_code_file_is_null
        fi

        return 0
    }
# </code>

# <summary> #3 - User validation </summary>
# <code>
    # <summary> Check if current user is sudo or root. </summary>
    # <returns> void </returns>
    function CheckIfUserIsRoot
    {
        # <params>
        local readonly str_file=$( basename $0 )
        local readonly str_output_user_is_not_root="${var_prefix_warn} User is not Sudo/Root. In terminal, enter: ${var_yellow}'sudo bash ${str_file}' ${var_reset}"
        # </params>

        if [[ $( whoami ) != "root" ]]; then
            echo -e $str_output_user_is_not_root
            return 1
        fi

        return 0
    }
# </code>

# <summary> #4 - File operation and validation </summary>
# <code>
    # <summary> Create a directory. </summary>
    # <param name="$1"> the directory </param>
    # <returns> exit code </returns>
    #
    function CreateDir
    {
        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not create directory '$1'."
        # </params>

        if ! CheckIfDirExists $1; then
            return $?
        fi

        mkdir -p $1 || (
            echo -e $str_output_fail
            return 1
        )

        return 0
    }

    # <summary> Create a file. </summary>
    # <param name="$1"> the file </param>
    # <returns> exit code </returns>
    #
    function CreateFile
    {
        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not create file '$1'."
        # </params>

        if CheckIfFileExists $1 &> /dev/null; then
            return 0
        fi

        touch $1 || (
            echo -e $str_output_fail
            return 1
        )

        return 0
    }

    # <summary> Delete a dir/file. </summary>
    # <param name="$1"> the file </param>
    # <returns> exit code </returns>
    #
    function DeleteFile
    {
        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not delete file '$1'."
        # </params>

        if ! CheckIfFileExists $1; then
            return 0
        fi

        rm $1 || (
            echo -e $str_output_fail
            return 1
        )

        return 0
    }

    # <summary> Write output to a file. Declare '$var_file' before calling this function. </summary>
    # <param name="$1"> the file </param>
    # <param name="$var_file"> the file contents </param>
    # <returns> exit code </returns>
    #
    function WriteToFile
    {
        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not write to file '$1'."
        # </params>

        if ! CheckIfFileExists $1; then
            return "$?"
        fi

        if ! CheckIfVarIsValid $var_file; then
            return "$?"
        fi

        ( printf "%s\n" "${var_file[@]}" >> $1 ) || (
            echo -e $str_output_fail
            return 1
        )

        return 0
    }
# </code>

# <summary> #5 - Device validation </summary>
# <code>
    # <summary> Check if current kernel and distro are supported, and if the expected Package Manager is installed. </summary>
    # <returns> exit code </returns>
    function CheckLinuxDistro
    {
        # <params>
        local readonly str_kernel="$( uname -o | tr '[:upper:]' '[:lower:]' )"
        local readonly str_operating_system="$( lsb_release -is | tr '[:upper:]' '[:lower:]' )"
        local str_package_manager=""
        local readonly str_output_distro_is_not_valid="${var_prefix_error} Distribution '$( lsb_release -is )' is not supported."
        local readonly str_output_kernel_is_not_valid="${var_prefix_error} Kernel '$( uname -o )' is not supported."
        local readonly str_OS_with_apt="debian bodhi deepin knoppix mint peppermint pop ubuntu kubuntu lubuntu xubuntu "
        local readonly str_OS_with_dnf_yum="redhat berry centos cern clearos elastix fedora fermi frameos mageia opensuse oracle scientific suse"
        local readonly str_OS_with_pacman="arch manjaro"
        local readonly str_OS_with_portage="gentoo"
        local readonly str_OS_with_urpmi="opensuse"
        local readonly str_OS_with_zypper="mandriva mageia"
        # </params>

        if ! CheckIfVarIsValid $str_kernel &> /dev/null; then
            return $?
        fi

        if ! CheckIfVarIsValid $str_operating_system &> /dev/null; then
            return $?
        fi

        if [[ "${str_kernel}" != *"linux"* ]]; then
            echo -e $str_output_kernel_is_not_valid
            return 1
        fi

        # <summary> Check if current Operating System matches Package Manager, and Check if PM is installed. </summary>
        # <returns> exit code </returns>
        function CheckLinuxDistro_GetPackageManagerByOS
        {
            if [[ ${str_OS_with_apt} =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="apt"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

            elif [[ ${str_OS_with_dnf_yum} =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="dnf"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

                str_package_manager="yum"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

            elif [[ ${str_OS_with_pacman} =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="pacman"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

            elif [[ ${str_OS_with_portage} =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="portage"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

            elif [[ ${str_OS_with_urpmi} =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="urpmi"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

            elif [[ ${str_OS_with_zypper} =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="zypper"
                CheckIfCommandIsInstalled $str_package_manager &> /dev/null && return 0

            else
                str_package_manager=""
                return 1
            fi

            return 1
        }

        if ! CheckLinuxDistro_GetPackageManagerByOS; then
            echo -e $str_output_distro_is_not_valid
            return 1
        fi

        return 0
    }
# </code>

# <summary> Main </summary>
# <code>
    if ! CheckIfUserIsRoot; then
        exit "$?"
    fi

    IFS=$'\n'      # Change IFS to newline char

    # <params>
    bool_toggle_match_given_Intel_driver=false                     # check to ignore 'i915' driver and prioritize 'modesetting'
    str_outDir1='/etc/X11/xorg.conf.d/'
    str_outFile1="${str_outDir1}10-auto-xorg.conf"
    declare -lr var_option1=$1
    declare -lr var_option2=$2
    # </params>

    case "${var_option1}" in
        "y" )
            readonly bool_parse_PCI_in_order_by_Bus_ID=true
            ;;

        "n" | "" )
            readonly bool_parse_PCI_in_order_by_Bus_ID=false
            echo -e "${var_prefix_warn} Parsing VGA devices in reverse order."
            ;;

        # * )
            # echo -e "${var_prefix_fail} Invalid input. Missing argument [Y/n]."
            # exit 1
            # ;;
    esac

    if $bool_parse_PCI_in_order_by_Bus_ID; then
        declare -ar arr_PCI_ID=$( lspci -m | grep -E 'VGA|Graphics' | cut -d ' ' -f 1 )
    else
        declare -ar arr_PCI_ID=$( lspci -m | grep -E 'VGA|Graphics' | cut -d ' ' -f 1 | sort -r )
    fi

    # <summary> Exit early if system directory does not exist and cannot be created. </summary>
    if ! CheckIfDirExists $str_outDir1 &> /dev/null; then
    	CreateDir $str_outDir1 || exit "$?"
    fi

    DeleteFile $str_outFile1 &> /dev/null || exit "$?"

    # <summary> Exit early if existing system file cannot be overwritten. </summary>
    if ! CheckIfFileExists $str_outFile1 &> /dev/null; then
	CreateFile $str_outFile1 || exit "$?"
    fi

    # <summary> Find first or last valid VGA driver, given if parsing in forward or reverse order. </summary>
    # <returns> exit code </returns>
    function MatchValidVGADeviceWithDriver
    {
	if ! CheckIfVarIsValid $str_thisDriver &> /dev/null; then
            echo -e "Found Driver: 'N/A'"
	    return 1
	fi

        if [[ ( $str_thisType == *"vga"* || $str_thisType == *"graphics"* ) && $str_thisDriver != *"vfio-pci"* ]] && ( ! CheckIfVarIsValid $str_thisDriver &> /dev/null ); then

            # <summary> Match Intel VGA </summary>
            if [[ $str_thisVendor == *"intel"* ]]; then
                if [[ $bool_toggle_match_given_Intel_driver == true ]]; then
                    str_thisDriver="modesetting"
                else
                    echo -e "${var_prefix_warn} Should given parsed Intel VGA driver be invalid, replace xorg.conf with an alternate intel driver (example: 'modesetting')."
                fi
            fi
        fi

        echo -e "Found Driver: '$str_thisDriver'"
        return 0
    }

    # <summary> Find first or last valid VGA driver, given if parsing in forward or reverse order. </summary>
    # <returns> void </returns>
    function FindFirstOrLastValidVGADriver
    {
        for str_thisPCI_ID in ${arr_PCI_ID}; do

            # <params>
            str_thisDriver=$( lspci -ks $str_thisPCI_ID | grep -E 'driver' | cut -d ':' -f 2 | cut -d ' ' -f 2 )
            str_thisType=$( lspci -ms $str_thisPCI_ID | cut -d '"' -f 2 | tr '[:upper:]' '[:lower:]' )
            str_thisVendor=$( lspci -ms $str_thisPCI_ID | cut -d '"' -f 4 | tr '[:upper:]' '[:lower:]' )
            # str_thisBusID=$( echo $str_thisPCI_ID | cut -d ':' -f 1 )
            # str_thisSlotID=$( echo $str_thisPCI_ID | cut -d ':' -f 2 | cut -d '.' -f 1 )
            str_thisFuncID=$( echo $str_thisPCI_ID | cut -d '.' -f 2 )
            str_thisPCI_ID=$( echo $str_thisPCI_ID | cut -d '.' -f 1 )
            # str_thisPCI_ID=${str_thisBusID}":"${str_thisSlotID}":"${str_thisFuncID}             # <note> rearrange string for Xorg output
            str_thisPCI_ID+=":"${str_thisFuncID}
            # </params>

            echo -e "Found PCI ID: '$str_thisPCI_ID'"

            if MatchValidVGADeviceWithDriver; then
		return 0
            fi
        done

        return 1
    }

    if ! FindFirstOrLastValidVGADriver; then
        echo -e "${var_prefix_fail} No VGA devices found."
        exit 1
    fi

    if ! CheckIfFileExists $str_outDir1 &> /dev/null; then
        echo -e "${var_prefix_warn} Could not find directory '${str_outDir1}'."
        exit 1
    fi

    if ! CheckIfFileExists $str_outFile1 &> /dev/null; then
        echo -e "${var_prefix_warn} Missing project file '${str_outFile1}'."
        exit 1
    fi

    CheckIfVarIsValid $str_thisDriver &> /dev/null

    case "$?" in
        0 )
            declare -a var_file=(
                "# Generated by 'portellam/Auto-Xorg'"
                "#"
                "# WARNING: Any modifications to this file will be modified by 'Auto-Xorg'"
                "#"
                "# Execute \"lspci -k\" for Bus ID and Driver."
                "#"
                "\nSection\t\"Device\""
                "\tIdentifier\t\"Device0\""
                "\tDriver\t\t\"$str_thisDriver\""
                "\tBusID\t\t\"PCI:$str_thisPCI_ID\""
                "EndSection"
            )

            echo -e "Valid VGA device found."

            if ! WriteToFile $str_outFile1; then
                exit 1
            fi
            ;;

        * )
            declare -a var_file=(
                "# Generated by 'portellam/Auto-Xorg'"
                "#"
                "# WARNING: Any modifications to this file will be modified by 'Auto-Xorg'"
                "#"
                "# Execute \"lspci -k\" for Bus ID and Driver."
                "#"
                "\nSection\t\"Device\""
                "\tIdentifier\t\"Device0\""
                "\tDriver\t\t\"driver_name\""
                "\tBusID\t\t\"PCI:bus_id:slot_id:function_id\""
                "EndSection"
            )

            echo -e "${var_prefix_warn} No valid VGA device found."

            if ! WriteToFile $str_outFile1; then
                exit 1
            fi

            exit 0
            ;;
    esac

    # <summary> Find display manager. </summary>
    str_DM=$( cat /etc/X11/default-display-manager )

    if ! CheckIfCommandIsInstalled $str_DM; then
        echo -e "${var_prefix_warn} No default display manager found."
    fi

    str_DM="${str_DM##*/}"

    # <summary> Restart system service automatically or manually. </summary>
    case "dm" in
        $var_option2 )
            systemctl enable $str_DM
            systemctl restart $str_DM
            ;;

        *)
            echo -e "You may restart the active display manager '$str_DM'.\nTo restart, execute ${var_yellow}'sudo systemctl restart $str_DM'${var_reset}."
            ;;
    esac

    exit 0
# </code>
