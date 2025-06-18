#!/bin/sh

# modidied version of cli.sh to use with sh
msg() {
    # Use a static variable to store previous message length
    if [ -z "${_msg_prev_len+x}" ]; then
        _msg_prev_len=0
    fi

    # Use a static variable to store the newline state
    if [ -z "${_msg_prev_newline+x}" ]; then
        _msg_prev_newline=true
    fi

    # Check if the previous message ended with a newline
    if [ "$_msg_prev_newline" = "false" ]; then
        # If the previous message did not end with a newline, we need to clear the line
        i=0
        while [ $i -lt $_msg_prev_len ]; do
            echo -n " "
            i=$((i + 1))
        done

        # Move the cursor back to the start of the line
        printf "\r"
    fi

    # Check if the first argument is -n, which means no newline at the end
    if [ "$1" = "-n" ]; then
        shift
        _msg_prev_newline="false"
    else
        _msg_prev_newline="true"
    fi

    # default variables
    local message="$@"
    _msg_prev_len=${#message}

    if [ "$_msg_prev_newline" = "true" ]; then
        printf "%b\n" "$message"
    else
        printf "%b\r" "$message"
    fi
}

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
pink=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

if [ $(id -u) -ne 0 ]; then
    echo "${red}This script should be run as root. Please run it with sudo.${reset}"
    exit 1
fi

# Detect Linux distribution
distro="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro="$ID"
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    distro="$DISTRIB_ID"
elif [ -f /etc/redhat-release ]; then
    distro="rhel"
elif [ -f /etc/arch-release ]; then
    distro="arch"
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/cli.sh)"

if [ -f "$HOME/.xsetup-cache" ]; then
    . $HOME/.xsetup-cache

    if [ -z "${new_user+x}" ] || [ -z "$new_user" ]; then
        echo "${red}No user account found. Please create a user account first.${reset}"
        exit 1
    fi

    msg "${blue}Installing XFCE4 desktop environment...${reset}\n"
    case "$distro" in
        ubuntu|debian)
            su -- $new_user -c "sudo apt install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio" # xfce4-panel xfce4-session xfce4-settings xfwm4 lightdm lightdm-gtk-greeter"
            ;;
        alpine)
            su -- $new_user -c "apk add dbus xorg-xwayland xfce4 xfce4-terminal pulseaudio"
            ;;
        fedora|rhel|centos)
            su -- $new_user -c "sudo dnf install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio"
            ;;
        archarm|archlinux32)
            su -- $new_user -c "sudo pacman -S --noconfirm dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio"
            ;;
        *)
            echo "${red}Unsupported distribution: $distro${reset}"
            exit 1
            ;;
    esac
    msg "\n${green}XFCE4 desktop environment installed successfully!${reset}"
else
    msg "${red}To install XFCE4 desktop environment, you need to have a user account with sudo privileges. For security reasons, a user account is required to install desktop environments and graphical applications.${reset}"
    exit 1
fi