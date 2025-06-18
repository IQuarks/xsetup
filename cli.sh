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

echo "${cyan}Detected distribution: $distro${reset}"

msg "${green}Updating and upgrading packages...${reset}\n"
case "$distro" in
    ubuntu|debian)
        apt update && apt upgrade -y
        if [ $? -ne 0 ]; then
            echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
            exit 1
        fi
        msg "\nUpgrade complete!"

        msg -n "${green}Installing required packages...${reset}"
        apt install -y zsh curl sudo > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${red}Failed to install required packages. Please check your package manager.${reset}"
            exit 1
        fi
        ;;
    alpine)
        apk update && apk upgrade
        if [ $? -ne 0 ]; then
            echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
            exit 1
        fi
        msg "\nUpgrade complete!"

        msg -n "${green}Installing required packages...${reset}"
        apk add zsh curl sudo > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${red}Failed to install required packages. Please check your package manager.${reset}"
            exit 1
        fi
        ;;
    fedora|rhel|centos)
        dnf update -y && dnf upgrade -y
        if [ $? -ne 0 ]; then
            echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
            exit 1
        fi
        msg "\nUpgrade complete!"

        msg -n "${green}Installing required packages...${reset}"
        dnf install -y zsh curl sudo > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${red}Failed to install required packages. Please check your package manager.${reset}"
            exit 1
        fi
        ;;
    archarm|archlinux32)
        pacman -Syu --noconfirm
        if [ $? -ne 0 ]; then
            echo "${red}Failed to upgrade packages. Please check your package manager.${reset}"
            exit 1
        fi
        msg "\nUpgrade complete!"

        msg -n "${green}Installing required packages...${reset}"
        pacman -S --noconfirm zsh curl sudo > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${red}Failed to install required packages. Please check your package manager.${reset}"
            exit 1
        fi
        ;;
    *)
        echo "${red}Unsupported distribution: $distro${reset}"
        exit 1
        ;;
esac
msg "${green}Required packages installed successfully!${reset}"

read -p "Do you want a new user? (y/n) (default: n): " create_user
create_user=${create_user:-n}
if [ "$create_user" = "y" ]; then
    read -p "Enter the new username: " new_user
    if id "$new_user" >/dev/null 2>&1; then
        echo "${red}User $new_user already exists. Please choose a different username.${reset}"
    else
        echo "${green}Creating user $new_user...${reset}"

        case "$distro" in
            ubuntu|debian)
                adduser $new_user --shell /bin/zsh
                ;;
            alpine)
                adduser $new_user -s /bin/zsh
                ;;
            fedora|rhel|centos)
                adduser $new_user --shell /bin/zsh
                ;;
            archarm|archlinux32)
                useradd $new_user -m -s /bin/zsh
                ;;
            *)
                echo "${red}Unsupported distribution: $distro${reset}"
                exit 1
                ;;
        esac
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

    echo "new_user=$new_user" > $HOME/.xsetup-cache

    msg "${blue}Installing neovim, cmake, and git for user $new_user...${reset}\n"
    case "$distro" in
        ubuntu|debian)
            su -- $new_user -c "sudo apt install -y neovim cmake git"
            ;;
        alpine)
            su -- $new_user -c "apk add neovim cmake git"
            ;;
        fedora|rhel|centos)
            su -- $new_user -c "sudo dnf install -y neovim cmake git"
            ;;
        archarm|archlinux32)
            su -- $new_user -c "sudo pacman -S --noconfirm neovim cmake git"
            ;;
        *)
            echo "${red}Unsupported distribution: $distro${reset}"
            exit 1
            ;;
    esac
    msg "\n${green}Installation complete!${reset}"
fi
