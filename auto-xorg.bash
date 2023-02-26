#!/bin/bash sh

#
# Filename:         auto-xorg
# Description:      Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <remarks> Exit codes, Evaluations, Statements </remarks>
    # <params>
        # <summary> Exit codes </summary>
        declare -i int_code_partial_completion=255
        declare -i int_code_skipped_operation=254
        declare -i int_code_var_is_null=253
        declare -i int_code_var_is_empty=252
        declare -i int_code_var_is_not_bool=251
        declare -i int_code_var_is_NAN=250
        declare -i int_code_pointer_is_var=249
        declare -i int_code_dir_is_null=248
        declare -i int_code_file_is_null=247
        declare -i int_code_file_is_not_executable=246
        declare -i int_code_file_is_not_writable=245
        declare -i int_code_file_is_not_readable=244
        declare -i int_code_cmd_is_null=243
        declare -i int_exit_code=$?

        # <summary>
        # Color coding
        # Reference URL: 'https://www.shellhacks.com/bash-colors'
        # </summary>
        var_blinking_red='\033[0;31;5m'
        var_blinking_yellow='\033[0;33;5m'
        var_green='\033[0;32m'
        var_red='\033[0;31m'
        var_yellow='\033[0;33m'
        var_reset_color='\033[0m'

        # <summary> Append output </summary>
        var_prefix_caution="${var_yellow}Caution:${var_reset_color}"
        var_prefix_error="${var_yellow}Error:${var_reset_color}"
        var_prefix_fail="${var_red}Failure:${var_reset_color}"
        var_prefix_pass="${var_green}Success:${var_reset_color}"
        var_prefix_warn="${var_blinking_red}Warning:${var_reset_color}"
        var_suffix_fail="${var_red}Failure${var_reset_color}"
        var_suffix_maybe="${var_yellow}Incomplete${var_reset_color}"
        var_suffix_pass="${var_green}Success${var_reset_color}"
        var_suffix_skip="${var_yellow}Skipped${var_reset_color}"

        # <summary> Output statement </summary>
        str_output_partial_completion="${var_prefix_warn} One or more operations failed."
        str_output_please_wait="The following operation may take a moment. ${var_blinking_yellow}Please wait.${var_reset_color}"
        str_output_var_is_not_valid="${var_prefix_error} Invalid input."
    # </params>

# <remarks> Functions </remarks>
# <code>
    # <summary> Copied from 'portellam/bashlib' </summary>
        # <summary> Check if current user is sudo or root. </summary>
        # <returns> exit code </returns>
        function IsSudoUser
        {
            # <params>
            local readonly str_fail="${var_prefix_warn} User is not sudo/root."
            # </params>

            if [[ $( whoami ) != "root" ]]; then
                echo -e "${str_fail}"
                return 1
            fi

            return 0
        }

        # <summary> Check if the array is empty. </summary>
        # <paramref name=$1> string: name of the array </paramref>
        # <returns> exit code </returns>
        function IsArray
        {
            IsString $1 || return $?

            # <params>
            local readonly str_fail="${var_prefix_error} Empty array."
            local readonly var_get_array='echo "${'$1'[@]}"'
            local readonly var_get_array_len='echo "${#'$1'[@]}"'
            # </params>

            for var_element in $( eval "${var_get_array}" ); do
                IsString "${var_element}" && return $?
            done

            if [[ $( eval "${var_get_array_len}" ) -eq 0 ]]; then
                echo -e "${str_fail}"
                return "${int_code_var_is_empty}"
            fi

            return 0
        }

        # <summary> Check if the directory exists. If true, pass. </summary>
        # <param name=$1> string: the directory name </param>
        # <returns> exit code </returns>
        function IsDir
        {
            IsString $1 || return $?

            # <params>
            local readonly str_fail="${var_prefix_error} File '${1}' is not a directory."
            # </params>

            if [[ ! -d $1 ]]; then
                echo -e "${str_fail}"
                return "${int_code_dir_is_null}"
            fi

            return 0
        }

        # <summary> Check if the file exists. If true, pass. </summary>
        # <param name=$1> string: the file name </param>
        # <returns> exit code </returns>
        function IsFile
        {
            IsString $1 || return $?

            # <params>
            local readonly str_fail="${var_prefix_error} '${1}' is not a file."
            # </params>

            if [[ ! -e "${str_file}" ]]; then
                echo -e "${str_fail}"
                return "${int_code_dir_is_null}"
            fi

            return 0
        }

        # <summary> Check if the variable is not empty. If true, pass. </summary>
        # <param name=$1> var: the variable </param>
        # <returns> exit code </returns>
        function IsString
        {
            # <params>
            local readonly str_fail="${var_prefix_error} Empty string."
            local readonly var="${1}"
            # </params>

            if [[ "${#var}" -eq 0 && "${var}" == "" ]]; then
                echo -e "${str_fail}"
                return "${int_code_var_is_empty}"
            fi

            return 0
        }

        # <summary> Write output to a file. Declare inherited params before calling this function. </summary>
        # <paramref name=$1> string: the name of the array </paramref>
        # <param name=$2> string: the name of the file </param>
        # <returns> exit code </returns>
        function WriteFile
        {
            IsFile $2 &> /dev/null && return 1
            IsArray $1 || return $?

            # <params>
            local readonly str_fail="${var_prefix_fail} Could not write to file '${1}'."
            local readonly var_set_param='printf "%s\n" "${'$1'[@]}" >> $2'
            # </params>

            if ! eval "${var_set_param}"; then
                echo -e "${str_fail}"
                return 1
            fi

            return 0
        }

    # <summary> Program code </summary>
        # <summary> Find first valid VGA driver. </summary>
        # <returns> exit code </returns>
        function FindFirstVGADriver
        {
            for var_PCI_ID in "${arr_PCI_ID[@]}"; do
                # <params>
                str_driver=$( lspci -ks "${var_PCI_ID}" | grep -E 'driver' | cut -d ':' -f 2 | cut -d ' ' -f 2 )
                str_type=$( lspci -ms "${var_PCI_ID}" | cut -d '"' -f 2 | tr '[:upper:]' '[:lower:]' )
                str_vendor=$( lspci -ms "${var_PCI_ID}" | cut -d '"' -f 4 | tr '[:upper:]' '[:lower:]' )
                str_function_ID=$( echo "${var_PCI_ID}" | cut -d '.' -f 2 )
                str_PCI_ID=$( echo "${var_PCI_ID}" | cut -d '.' -f 1 )
                str_PCI_ID+=":${str_function_ID}"
                # </params>

                MatchValidVGADeviceWithDriver && return 0
            done

            return 1
        }

        # <summary> Gets the current option </summary>
        # <returns> exit code </returns>
        function GetOption
        {
            while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
                "-f" | "--first" )
                    bool_parse_PCI_order_by_Bus_ID=true
                    ;;

                "-l" | "--last" )
                    bool_parse_PCI_order_by_Bus_ID=false
                    echo -e "${var_prefix_caution} Parsing VGA devices in reverse order."
                    ;;

                "-r" | "--restart-display" )
                    bool_do_restart_display_manager=true
                    ;;

                "-a" | "--amd" )
                    if $bool_prefer_any_brand; then bool_prefer_AMD=true; fi
                    ;;

                "-i" | "--intel" )
                    if $bool_prefer_any_brand; then bool_prefer_Intel=true; fi
                    ;;

                "-n" | "--nvidia" )
                    if $bool_prefer_any_brand; then bool_prefer_NVIDIA=true; fi
                    ;;

                "-o" | "--other" )
                    if $bool_prefer_any_brand; then bool_prefer_off_brand=true; fi
                    ;;

                "" )
                    ;;

                "-h" | "--help" )
                    return 1
                    ;;

                * )
                    echo -e "${var_prefix_warn} Invalid input."
                    return 1
                    ;;
            esac; shift; done

            if [[ "$1" == '--' ]]; then shift; fi
            IsString "${var_get_preferred_vendor}" &> /dev/null || SetPreferredBrand
            return 0
        }

        # <summary> Gets the usage. </summary>
        # <returns> exit code </returns>
        function GetUsage
        {
            IFS=$'\n'

            local readonly arr_output=(
                "Usage: bash auto-xorg [OPTION]"
                "Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.\n"
                "\t-f, --first\t\tfind the first valid VGA device"
                "\t-h, --help\t\tPrint this usage statement"
                "\t-l, --last\t\tfind the last valid VGA device"
                "\t-r, --restart-display\trestart the display manager immediately"
                "\n\tPrefer a vendor:\n"
                "\t-a, --amd\t\tAMD or ATI"
                "\t-i, --intel\t\tIntel"
                "\t-n, --nvidia\t\tNVIDIA"
                "\t-o, --other\t\tany other brand (past or future)"
                "\nExample:"
                "\tbash auto-xorg -l -n -r\tFind last valid NVIDIA VGA device, then restart the display manager immediately."
            )

            echo -e "${arr_output[*]}"
            return 0
        }

        # <summary> Find first or last valid VGA driver, given if parsing in forward or reverse order. </summary>
        # <param name="$str_driver"> string: the name of the driver </param>
        # <returns> exit code </returns>
        function MatchValidVGADeviceWithDriver
        {
            if ! IsString $str_driver &> /dev/null; then
                echo -e "Found Driver: 'N/A'"
                return 1
            fi

            if ( [[ $str_type =~ ^"vga" ]] || [[ $str_type =~ ^"graphics" ]] ) && ! [[ $str_driver =~ ^"vfio-pci" ]]; then
                local var_set_preferred_vendor=""

                # <remarks> Match Intel VGA </remarks>
                if [[ $str_vendor == *"intel"* ]]; then
                    if [[ $bool_toggle_match_given_Intel_driver == true ]]; then
                        str_driver="modesetting"
                    else
                        echo -e "${var_prefix_caution} Should given parsed Intel VGA driver be invalid, replace xorg.conf with an alternate intel driver (example: 'modesetting')."
                    fi
                fi

                # <remarks> Print </remarks>
                echo -e "Found Driver: '$str_driver'"

                # <remarks> Set evaluation if a preferred driver is given. </remarks>
                if IsString $var_get_preferred_vendor &> /dev/null; then
                    var_set_preferred_vendor='echo "${str_vendor}" | '$( echo "${var_get_preferred_vendor}" | grep -iv 'corporation' )
                    local str_preferred_vendor=$( eval $var_set_preferred_vendor )
                else
                    local str_preferred_vendor=""
                fi

                # <summary> Exit early if a preferred driver is not found. </summary>
                if IsString $var_get_preferred_vendor &> /dev/null && ! IsString $str_preferred_vendor &> /dev/null; then
                    return 1
                fi

                return 0
            fi

            return 1
        }

        # <summary> Set global parameters </summary>
        # <returns> exit code </returns>
        function SetGlobals
        {
            # <params>
            str_display_manager=$( cat /etc/X11/default-display-manager )
            str_display_manager="${str_display_manager##*/}"
            str_dir1="/etc/X11/xorg.conf.d/"
            str_file1="${str_dir1}10-auto-xorg.conf"

                # <remarks> Permanent Toggles </remarks>
                bool_toggle_match_given_Intel_driver=true

                # <remarks> File contents </remarks>
                declare -ar arr_file_disclaimer=(
                    "#### Generated by 'portellam/Auto-Xorg'"
                    "# WARNING: Any modifications to this file will be modified by 'Auto-Xorg'"
                    "# Run lspci to view hardware information."
                    "#"
                )

                declare -ga arr_file1=(
                    "${arr_file_disclaimer[@]}"
                )

                # <remarks> Toggles </remarks>
                bool_do_restart_display_manager=false
                bool_parse_PCI_order_by_Bus_ID=false
                bool_prefer_any_brand=true
                bool_prefer_AMD=false
                bool_prefer_Intel=false
                bool_prefer_NVIDIA=false
                bool_prefer_off_brand=false

                # <remarks> Evaluations </remarks>
                var_get_preferred_vendor=""
                readonly var_get_PCI_ID='lspci -m | grep -Ei "vga|graphics" | cut -d " " -f 1'
                readonly var_get_PCI_ID_reverse_sort='lspci -m | grep -Ei "vga|graphics" | cut -d " " -f 1 | sort -r'
            # </params>

            return 0
        }

        # <summary> Save contents to file. If no device is found, leave comments in place of details. </summary>
        # <returns> exit code </returns>
        function SetFile
        {
            case $? in
                0 )
                    arr_file1+=(
                        ""
                        "Section        \"Device\""
                        "   Identifier  \"Device0\""
                        "   Driver      \"$str_driver\""
                        "   BusID       \"PCI:$str_PCI_ID\""
                        "EndSection"
                    )

                    echo -e "Valid VGA device found."
                    ;;

                * )
                    arr_file1+=(
                        ""
                        "Section        \"Device\""
                        "   Identifier  \"Device0\""
                        "   Driver      \"driver_name\""
                        "   BusID       \"PCI:bus_id:slot_id:function_id\""
                        "EndSection"
                    )

                    echo -e "${var_prefix_warn} No valid VGA device found."
                    ;;
            esac

            WriteFile "arr_file1" $str_file1
            return $?
        }

        # <summary> Sets the options. Exit early (Pass) if input is null. Else, exit early (Fail) if input is invalid. </summary>
        # <param name="$@"> array: the input parameters </param>
        # <returns> exit code </returns>
        function SetOptions
        {
            for var_option in $@; do
                IsString $var_option || return $?
                GetOption $var_option || return $?
            done

            return 0
        }

        # <summary> Sets evaluation given a preferred brand. </summary>
        # <returns> exit code </returns>
        function SetPreferredBrand
        {
            case true in
                $bool_prefer_AMD )
                    var_get_preferred_vendor="grep -iv 'amd|ati'"
                    ;;

                $bool_prefer_Intel )
                    var_get_preferred_vendor="grep -i 'intel'"
                    ;;

                $bool_prefer_NVIDIA )
                    var_get_preferred_vendor="grep -i 'nvidia'"
                    ;;

                $bool_prefer_off_brand )
                    var_get_preferred_vendor="grep -Eiv 'amd|ati|intel|nvidia'"
                    ;;
            esac

            IsString "${var_get_preferred_vendor}" &> /dev/null && bool_prefer_any_brand=false
            return 0
        }

        # <summary> Main code block </summary>
        # <returns> exit code </returns>
        function Main
        {
            IsSudoUser || return $?
            SetGlobals
            if ! SetOptions $@; then GetUsage; return $?; fi

            # <remarks> Toggle the sort order of parse of PCI devices. </remarks>
            if $bool_parse_PCI_order_by_Bus_ID; then
                declare -a arr_PCI_ID=( $( eval $var_get_PCI_ID ) )
            else
                declare -a arr_PCI_ID=( $( eval $var_get_PCI_ID_reverse_sort ) )
            fi

            # <remarks> Exit early if no PCI devices are found (NOTE: more likely that the command fails, than no PCI devices exist). </remarks>
            if ! IsArray "arr_PCI_ID"; then
                echo -e "${var_prefix_fail} No PCI devices found."
                return 1
            fi

            # <remarks> Exit early if system directory does not exist and cannot be created. </remarks>
            if ! IsDir $str_dir1 &> /dev/null; then
                CreateDir $str_dir1 || return $?
            fi

            # <remarks> Exit early if existing system file cannot be overwritten. </remarks>
            rm $str_file1 || return $?

            # <remarks> Find first valid VGA driver. </remarks>
            FindFirstVGADriver
            declare -i int_exit_code=$?

            if [[ $int_exit_code -ne 0 ]] && IsString $var_get_preferred_vendor &> /dev/null; then
                var_get_preferred_vendor=""
                FindFirstVGADriver
                int_exit_code=$?
            fi

            if [[ $int_exit_code -ne 0 ]]; then
                echo -e "${var_prefix_fail} No VGA devices found."
                return 1
            fi

            # <remarks> Write to file if directory exists and driver is valid. </remarks>
            IsDir $str_dir1 || return 1
            IsString $str_driver &> /dev/null
            SetFile || return $?

            # <remarks> Restart system service automatically or manually. </remarks>
            if $bool_do_restart_display_manager; then
                systemctl enable $str_display_manager || return 1
                systemctl restart $str_display_manager || return 1
            else
                echo -e "You may restart the active display manager '${str_display_manager}'.\nTo restart, execute ${var_yellow}'sudo systemctl restart ${str_display_manager}'${var_reset}."
            fi

            return 0
        }
# </code>

# <remarks> Main </remarks>
# <code>
    Main $@
    exit $?
# </code>