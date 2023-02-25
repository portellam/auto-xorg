#!/bin/bash sh

#
# Filename:         auto-xorg
# Description:      Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device.
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <remarks> Functions </remarks>
# <code>
    # <summary> Copied from 'portellam/bashlib' </summary>
        # <summary> Create a file. </summary>
        # <param name=$1> string: the file </param>
        # <returns> exit code </returns>
        function CreateFile
        {
            IsString $1 || return $?
            IsFile $1 &> /dev/null && return 0

            # <params>
            local readonly str_fail="${var_prefix_fail} Could not create file '${1}'."
            local readonly var_command='touch '"$1"' &> /dev/null'
            # </params>

            if ! eval "${var_command}"; then
                echo -e "${str_fail}"
                return 1
            fi

            return 0
        }

        # <summary> Delete a file. </summary>
        # <param name=$1> string: the file </param>
        # <returns> exit code </returns>
        function DeleteFile
        {
            IsString $1 || return $?
            IsFile $1 &> /dev/null || return 1

            # <params>
            local readonly str_fail="${var_prefix_fail} Could not delete file '${1}'."
            local readonly var_command='rm '"$1"' &> /dev/null'
            # </params>

            if ! eval "${var_command}"; then
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
            local readonly str_dir=$( dirname $1 )
            local readonly str_file=$( basename $1 )
            # </params>

            IsString "${str_dir}" && cd "${str_dir}"

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

                echo -e "Found PCI ID: '${str_PCI_ID}'"
                MatchValidVGADeviceWithDriver && return $?
            done

            return 1
        }

        # <summary> Gets the current option </summary>
        # <returns> exit code </returns>
        function GetOption
        {
            while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
                "-f" || "--first" )
                    bool_parse_PCI_in_order_Bus_ID=true
                    ;;

                "-l" || "--last" )
                    bool_parse_PCI_in_order_Bus_ID=false
                    echo -e "${var_prefix_warn} Parsing VGA devices in reverse order."
                    ;;

                "-r" || "--restart-display" )
                    bool_do_restart_display_manager=true
                    ;;

                "-a" || "--amd" )
                    if ! $bool_prefer_any_brand; then bool_prefer_AMD=true; fi
                    ;;

                "-i" || "--intel" )
                    if ! $bool_prefer_any_brand; then bool_prefer_Intel=true; fi
                    ;;

                "-n" || "--nvidia" )
                    if ! $bool_prefer_any_brand; then bool_prefer_NVIDIA=true; fi
                    ;;

                "-o" || "--other" )
                    if ! $bool_prefer_any_brand; then bool_prefer_off_brand=true; fi
                    ;;

                # "" )
                #     return 0
                #     ;;

                * )
                    return 1
                    ;;

                ;;
            esac; shift; done

            if [[ "$1" == '--' ]]; then shift; fi

            return 0
        }

        # <summary> Gets the usage. </summary>
        # <returns> exit code </returns>
        function GetUsage
        {
            local readonly str_output=$( cat <<<
                "Usage: bash auto-xorg [OPTION]"
                "Generates Xorg (video output) for the first or last valid non-VFIO video (VGA) device."
                "\newline"
                "\t-f, --first\t\tfind first valid VGA device"
                "\t-l, --last\t\tfind last valid VGA device"
                "\newline"
                "\t-r, --restart-display\trestart display manager now"
                "\newline"
                "\t-a, --amd\t\tprefer AMD/ATI VGA device"
                "\t-i, --intel\t\tprefer Intel VGA device"
                "\t-n, --nvidia\t\tprefer NVIDIA VGA device"
                "\t-o, --other\t\tprefer off-brand VGA device"
                "\newline"
                "Examples:"
                "\tbash auto-xorg -l -n -r\tFind last valid NVIDIA VGA device and restart display manager immediately."
            )

            echo -e "${str_output}"

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

            if [[ ( $str_type == *"vga"* || $str_type == *"graphics"* ) && $str_driver != *"vfio-pci"* ]] && ( ! IsString $str_driver &> /dev/null ); then
                local var_set_preferred_vendor=""

                # <remarks> Match Intel VGA </remarks>
                if [[ $str_vendor == *"intel"* ]]; then
                    if [[ $bool_toggle_match_given_Intel_driver == true ]]; then
                        str_driver="modesetting"
                    else
                        echo -e "${var_prefix_warn} Should given parsed Intel VGA driver be invalid, replace xorg.conf with an alternate intel driver (example: 'modesetting')."
                    fi
                fi

                # <remarks> Print </remarks>
                echo -e "Found Driver: '$str_driver'"

                # <remarks> Set evaluation if a preferred driver is given. </remarks>
                if IsString $var_get_preferred_vendor &> /dev/null; then
                    var_set_preferred_vendor='echo "${str_vendor}" |'$( echo "${var_get_preferred_vendor}" )
                fi

                # <summary> Exit early if a preferred driver is not found. </summary>
                    # <remarks> Expected successful execution of on-brand evaluation will return a zero value </remarks>
                    if $bool_prefer_off_brand && IsString $var_set_preferred_vendor &> /dev/null && ! eval $var_set_preferred_vendor; then
                        return 1
                    fi

                    # <remarks> Expected successful execution of off-brand evaluation will return a non-zero value </remarks>
                    if ! $bool_prefer_off_brand && IsString $var_set_preferred_vendor &> /dev/null && eval $var_set_preferred_vendor; then
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
            readonly str_dir1="/etc/X11/xorg.conf.d/"
            readonly str_file1="10-auto-xorg.conf"

                # <remarks> Permanent Toggles </remarks>
                readonly bool_toggle_match_given_Intel_driver=true

                # <remarks> File contents </remarks>
                declare -ar arr_file_disclaimer=(
                    "#### Generated by 'portellam/Auto-Xorg'"
                    "# WARNING: Any modifications to this file will be modified by 'Auto-Xorg'"
                    "# Run lspci to view hardware information."
                    "#"
                )

                declare -a arr_file1=(
                    "${arr_file_disclaimer[@]}"
                )

                # <remarks> Toggles </remarks>
                bool_do_restart_display_manager=false
                bool_parse_PCI_order_by_Bus_ID=false
                bool_prefer_any_brand=false
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
                    readonly arr_file1+=(
                        "\nSection\t\"Device\""
                        "\tIdentifier\t\"Device0\""
                        "\tDriver\t\t\"$str_driver\""
                        "\tBusID\t\t\"PCI:$str_PCI_ID\""
                        "EndSection"
                    )

                    echo -e "Valid VGA device found."
                    ;;

                * )
                    readonly arr_file1+=(
                        "\nSection\t\"Device\""
                        "\tIdentifier\t\"Device0\""
                        "\tDriver\t\t\"driver_name\""
                        "\tBusID\t\t\"PCI:bus_id:slot_id:function_id\""
                        "EndSection"
                    )

                    echo -e "${var_prefix_warn} No valid VGA device found."
                    ;;
            esac

            WriteToFile "arr_file1" $str_file1
            return $?
        }

        # <summary> Sets the options. Exit early (Pass) if input is null. Else, exit early (Fail) if input is invalid. </summary>
        # <param name="$@"> array: the input parameters </param>
        # <returns> exit code </returns>
        function SetOptions
        {
            for var_option in $@; do
                IsString $var_option &> /dev/null || return $?
                GetOption $var_option || return $?
            done

            return 0
        }

        function SetPreferredBrand
        {
            case true in
                $bool_prefer_AMD )
                    readonly var_get_preferred_vendor="grep -iv 'amd|ati'"
                    ;;

                $bool_prefer_Intel )
                    readonly var_get_preferred_vendor="grep -i 'intel'"
                    ;;

                $bool_prefer_NVIDIA )
                    readonly var_get_preferred_vendor="grep -i 'nvidia'"
                    ;;

                $bool_prefer_off_brand )
                    readonly var_get_preferred_vendor="grep -Eiv 'amd|ati|intel|nvidia'"
                    ;;
            esac

            return 0
        }

        # <summary> Main code block </summary>
        # <returns> exit code </returns>
        function Main
        {
            IsSudoUser || return $?
            SetGlobals || return $?
            SetOptions $@ || GetUsage || return $?

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

            DeleteFile $str_file1 &> /dev/null || return $?

            # <remarks> Exit early if existing system file cannot be overwritten. </remarks>
            if ! IsFile $str_file1 &> /dev/null; then
                CreateFile $str_file1 || return $?
            fi

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

            # <remarks> ??? </remarks>
            IsDir $str_dir1 || return 1
            IsFile $str_file1 || return 1
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
    GetUsage
    # Main
    exit $?
# </code>