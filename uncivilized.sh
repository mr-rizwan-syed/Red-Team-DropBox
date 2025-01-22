#!/bin/bash
#title:         uncivilized.sh
#description:   Removal Script
#author:        R12W4N
#==============================================================================

[ "$DEBUG" == 'true' ] && set -x
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`
BLUE=`tput setaf 4`

if [[ $EUID -ne 0 ]]; then
   echo "${RED}This script must be run as root.${RESET}"
   exit 1
fi

function trap_ctrlc () {
    echo "${RED}Ctrl-C caught...performing cleanup${RESET}"
    trap "kill 0" EXIT
    exit 2
}
trap "trap_ctrlc" 2

function list_users() {
    echo "${GREEN}Available Users:${RESET}"
    ls /home
}

function validate_user() {
    local username="$1"
    if id -u "$username" &>/dev/null; then
        return 0
    else
        echo "${RED}User '$username' does not exist.${RESET}"
        return 1
    fi
}

function remove_user() {
    local username="$1"
    echo "${GREEN}Deleting user '$username'...${RESET}"
    userdel -r "$username" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "${GREEN}User '$username' removed successfully.${RESET}"
    else
        echo "${RED}Failed to remove user '$username'. Please check manually.${RESET}"
    fi
}

function remove_ssh_keys() {
    local username="$1"
    local ssh_dir="/home/$username/.ssh"
    if [[ -d "$ssh_dir" ]]; then
        echo "${GREEN}Removing SSH keys for '$username'...${RESET}"
        rm -rf "$ssh_dir"
        echo "${GREEN}SSH keys removed.${RESET}"
    else
        echo "${BLUE}No SSH keys found for '$username'.${RESET}"
    fi
}

function remove_rc_local_service() {
    echo "${GREEN}Disabling and removing rc-local.service...${RESET}"
    if systemctl is-enabled rc-local &>/dev/null; then
        sudo systemctl disable rc-local
    fi
    [[ -f /etc/systemd/system/rc-local.service ]] && rm -f /etc/systemd/system/rc-local.service
    [[ -f /etc/rc.local ]] && rm -f /etc/rc.local
    echo "${GREEN}rc-local.service removed.${RESET}"
}

function unsetup() {
    list_users
    read -p "${RED}Enter FalconPool Unit Name to remove: ${RESET}" FalconName
    validate_user "$FalconName" || exit 1

    echo "${GREEN}Proceeding with the removal of user '$FalconName'...${RESET}"
    remove_user "$FalconName"
    remove_ssh_keys "$FalconName"
    remove_rc_local_service
    echo "${GREEN}Cleanup completed. A reboot is recommended.${RESET}"
}

unsetup
