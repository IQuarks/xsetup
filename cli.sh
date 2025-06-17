#!/bin/sh

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

echo "${green}Updating and upgrading packages...${reset}"
if command -v apt >/dev/null 2>&1; then
    apt update && apt upgrade -y
    if [ $? -ne 0 ]; then
        echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
        exit 1
    fi

    echo "${green}Installing required packages...${reset}"
    apt install -y zsh curl sudo > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install required packages. Please check your package manager.${reset}"
        exit 1
    fi
elif command -v apk >/dev/null 2>&1; then
    apk update && apk upgrade -y
    if [ $? -ne 0 ]; then
        echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
        exit 1
    fi

    echo "${green}Installing required packages...${reset}"
    apk add zsh curl sudo > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install required packages. Please check your package manager.${reset}"
        exit 1
    fi
elif command -v dnf >/dev/null 2>&1; then
    dnf upgrade -y
    if [ $? -ne 0 ]; then
        echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
        exit 1
    fi

    echo "${green}Installing required packages...${reset}"
    dnf install -y zsh curl sudo > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install required packages. Please check your package manager.${reset}"
        exit 1
    fi
elif command -v yum >/dev/null 2>&1; then
    yum upgrade -y
    if [ $? -ne 0 ]; then
        echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
        exit 1
    fi

    echo "${green}Installing required packages...${reset}"
    yum install -y zsh curl sudo > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install required packages. Please check your package manager.${reset}"
        exit 1
    fi
elif command -v pacman >/dev/null 2>&1; then
    pacman -Syu --noconfirm
    if [ $? -ne 0 ]; then
        echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
        exit 1
    fi

    echo "${green}Installing required packages...${reset}"
    pacman -S --noconfirm zsh curl sudo > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install required packages. Please check your package manager.${reset}"
        exit 1
    fi
else
    echo "${red}No supported package manager found. Please install updates manually.${reset}"
    exit 1
fi

read -p "Do you want a new user? (y/n) (default: n): " create_user
create_user=${create_user:-n}
if [ "$create_user" = "y" ]; then
    read -p "Enter the new username: " new_user
    if id "$new_user" >/dev/null 2>&1; then
        echo "${red}User $new_user already exists. Please choose a different username.${reset}"
        exit 1
    else
        echo "${green}Creating user $new_user...${reset}"
        adduser $new_user -s /bin/zsh
        if [ $? -ne 0 ]; then
            echo "${red}Failed to create user $new_user. Please check your input.${reset}"
            exit 1
        fi

        echo "${new_user} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$new_user
        if [ $? -ne 0 ]; then
            echo "${red}Failed to add $new_user to sudoers. Please check your input.${reset}"
            exit 1
        fi
    fi

    echo $new_user > $HOME/.xsetup-cache
    
    if command -v apt >/dev/null 2>&1; then
        su -- $new_user -c "apt install -y neovim cmake git"
    elif command -v apk >/dev/null 2>&1; then
        su -- $new_user -c "apk add neovim cmake git"
    elif command -v dnf >/dev/null 2>&1; then
        su -- $new_user -c "dnf install -y neovim cmake git"
    elif command -v yum >/dev/null 2>&1; then
        su -- $new_user -c "yum install -y neovim cmake git"
    elif command -v pacman >/dev/null 2>&1; then
        su -- $new_user -c "pacman -S --noconfirm neovim cmake git"
    else
        echo "${red}No supported package manager found. Please install packages manually.${reset}"
        exit 1
    fi
fi