#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
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

            if [[ ! -e $1 ]]; then
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
        # <summary> Main code block </summary>
        # <returns> exit code </returns>
        function Main
        {
            if ! IsSudoUser; then
                return $?
            fi

            IFS=$'\n'      # Change IFS to newline char
            echo -en "Installing Auto-Xorg... "

            # <params>
            readonly str_dir1="/usr/sbin/"
            readonly str_dir2="/etc/systemd/system/"
            readonly str_file1="auto-xorg.bash"
            readonly str_file2="auto-xorg.service"
            # </params>

            if ! IsDir $str_dir1 &> /dev/null; then
                echo -e "${var_suffix_fail}"
                echo -e "${var_prefix_warn} Could not find directory '${str_dir1}'."
                return 1
            fi

            if ! IsFile $str_file1 &> /dev/null; then
                echo -e "${var_suffix_fail}"
                echo -e "${var_prefix_warn} Missing project file '${str_file1}'."
                return 1
            fi

            cp $str_file1 "${str_dir1}${str_file1}" || return 1
            chown root "${str_dir1}${str_file1}" || return 1
            chmod +x "${str_dir1}${str_file1}" || return 1

            if ! IsFile $str_dir2 &> /dev/null; then
                echo -e "${var_suffix_fail}"
                echo -e "${var_prefix_warn} Could not find directory '${str_dir2}'."
                return 1
            fi

            if ! IsFile $str_file2 &> /dev/null; then
                echo -e "${var_suffix_fail}"
                echo -e "${var_prefix_warn} Missing project file '${str_file2}'."
                return 1
            fi

            if ! cp $str_file2 "${str_dir2}${str_file2}" || ! chown root "${str_dir2}${str_file2}" || ! chmod +x "${str_dir2}${str_file2}"; then
                echo -e "${var_suffix_fail}"
                return 1
            fi

            echo -e "${var_suffix_pass}"
            systemctl enable --now $str_file2 && systemctl daemon-reload || return 1
            echo

            echo -e "${var_prefix_caution} It is NOT necessary to run ${var_yellow}'${str_file1}'${var_reset_color}.\n${var_yellow}'${str_file2}'${var_reset_color} will run automatically at boot, to grab the first non-VFIO VGA device.\nIf no available VGA device is found, an Xorg template will be created.\nTherefore, it will be assumed the system is running 'headless'."
            return 0
        }
# </code>

# <remarks> Main </remarks>
# <code>
    Main
    exit $?
# </code>