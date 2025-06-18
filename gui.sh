#!/bin/sh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/cli.sh)"

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

if [[ -f "$HOME/.xsetup-cache" ]]; then
    source $HOME/.xsetup-cache

    if command -v apt >/dev/null 2>&1; then
        su -- $new_user -c "sudo apt install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio" # xfce4-panel xfce4-session xfce4-settings xfwm4 lightdm lightdm-gtk-greeter"
    elif command -v apk >/dev/null 2>&1; then
        su -- $new_user -c "sudo apk add dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio"
    elif command -v dnf >/dev/null 2>&1; then
        su -- $new_user -c "sudo dnf install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio"
    elif command -v yum >/dev/null 2>&1; then
        su -- $new_user -c "sudo yum install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio"
    elif command -v pacman >/dev/null 2>&1; then
        su -- $new_user -c "sudo pacman -S --noconfirm dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio"
    else
        echo "${red}No supported package manager found. Please install packages manually.${reset}"
        exit 1
    fi
else
    if command -v apt >/dev/null 2>&1; then
        apt install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio # xfce4-panel xfce4-session xfce4-settings xfwm4 lightdm lightdm-gtk-greeter
    elif command -v apk >/dev/null 2>&1; then
        apk add dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio
    elif command -v yum >/dev/null 2>&1; then
        yum install -y dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm dbus-x11 xwayland xfce4 xfce4-terminal pulseaudio
    else
        echo "${red}No supported package manager found. Please install packages manually.${reset}"
        exit 1
    fi
fi