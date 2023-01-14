#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
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

# <summary> #1 - Exit codes </summary>
# <code>
    # <summary> Append Pass or Fail given exit code. If Fail, call SaveExitCode. </summary>
    # <returns> output statement </returns>
    function AppendPassOrFail
    {
        case "$?" in
            0)
                echo -e $var_suffix_pass
                return 0;;
            *)
                SaveExitCode
                echo -e $var_suffix_fail
                return $int_exit_code;;
        esac
    }

    # <summary> Save last exit code. </summary>
    # <param name="$int_exit_code"> the exit code </param>
    # <returns> void </returns>
    function SaveExitCode
    {
        int_exit_code="$?"
    }

# </code>

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

        if $( ! CheckIfVarIsValid $var_actual_install_path ) &> /dev/null || [[ "${var_actual_install_path}" != "${var_expected_install_path}" ]]; then
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

# <summary> Main </summary>
# <code>
    if ! CheckIfUserIsRoot; then
        exit "$?"
    fi

    IFS=$'\n'      # Change IFS to newline char

    echo -en "Installing Auto-Xorg... "

    # <params>
    readonly str_outDir1="/usr/sbin/"
    readonly str_outDir2="/etc/systemd/system/"
    readonly str_inFile1="auto-xorg.bash"
    readonly str_inFile2="auto-xorg.service"
    # </params>

    if ! CheckIfFileExists ${str_outDir1}; then
        echo -e $var_suffix_fail
        echo -e "${var_prefix_warn} Could not find directory '${str_outDir1}'."
        exit 1
    fi

    if ! CheckIfFileExists $str_inFile1; then
        echo -e $var_suffix_fail
        echo -e "${var_prefix_warn} Missing project file '${str_inFile1}'."
        exit 1
    fi

    cp $str_inFile1 ${str_outDir1}${str_inFile1} || exit 1
    chown root ${str_outDir1}${str_inFile1} || exit 1
    chmod +x ${str_outDir1}${str_inFile1} || exit 1

    if ! CheckIfFileExists ${str_outDir2}; then
        echo -e $var_suffix_fail
        echo -e "${var_prefix_warn} Could not find directory '${str_outDir2}'."
        exit 1
    fi

    if ! CheckIfFileExists $str_inFile2; then
        echo -e $var_suffix_fail
        echo -e "${var_prefix_warn} Missing project file '${str_inFile2}'."
        exit 1
    fi

    cp $str_inFile2 ${str_outDir2}${str_inFile2} || exit 1
    chown root ${str_outDir2}${str_inFile2} || exit 1
    chmod +x ${str_outDir2}${str_inFile2} || exit 1

    echo -e ${var_suffix_pass}
    systemctl enable $str_inFile2 || exit 1
    systemctl restart $str_inFile2 || exit 1
    systemctl daemon-reload || exit 1
    echo

    echo -e "Disclaimer: It is NOT necessary to run ${var_yellow}'$str_inFile1'${var_reset}.\n${var_yellow}'$str_inFile2'${var_reset} will run automatically at boot, to grab the first non-VFIO VGA device.\nIf no available VGA device is found, an Xorg template will be created.\nTherefore, it will be assumed the system is running 'headless'."

    exit
# </code>