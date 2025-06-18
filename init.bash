#!/bn/bash

msg() {
    # Use a static variable to store previous message length
    if [[ -z "${_msg_prev_len+x}" ]]; then
        _msg_prev_len=0
    fi

    # Use a static variable to store the newline state
    if [[ -z "${_msg_prev_newline+x}" ]]; then
        _msg_prev_newline=true
    fi

    # Check if the previous message ended with a newline
    if ! $_msg_prev_newline; then
        # If the previous message did not end with a newline, we need to clear the line
        for ((i=0; i<$_msg_prev_len; i++)); do
            echo -ne " "
        done

        # Move the cursor back to the start of the line
        echo -ne "\r"
    fi

    # Check if the first argument is -n, which means no newline at the end
    if [[ "$1" == "-n" ]]; then
        shift
        _msg_prev_newline=false
    else
        _msg_prev_newline=true
    fi

    # default variables
    local message="$@"
    _msg_prev_len=${#message}

    if $_msg_prev_newline; then
        set -- "${message}\n"
    else
        set -- "${message}\r"
    fi

    echo -ne "$@"
}

if [ -z "$(command -v pkg)" ]; then
  echo "pkg command not found. Please install pkg first."
  exit 1
fi

msg -n "Updating package repository..."
pkg update -f > /dev/null 2>&1

msg -n "Upgrading installed packages..."
pkg upgrade -y | while IFS= read -r line; do
  msg -n "${line}"
  sleep 0.05
done
msg "Upgrade complete!"

msg -n "Installing ncurses-utils..."
pkg install -y ncurses-utils > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to install ncurses-utils. Please check your package manager."
  exit 1
fi

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
pink=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

msg "${green}ncurses-utils installed successfully!${reset}"

if [ -z "$TERM" ]; then
  echo "TERM environment variable is not set. Please set it to a valid terminal type."
  exit 1
fi

if [ $(id -u) -eq 0 ]; then
    echo "${red}This script should not be run as root. Please run it as a regular user.${reset}"
    exit 1
fi

read -p "Choose an installation type [ cli, gui ] (press enter for cli): " install_type
install_type=${install_type:-cli}

if [ "$install_type" != "cli" ] && [ "$install_type" != "gui" ]; then
    echo "${red}Invalid installation type. Please choose 'cli' or 'gui'.${reset}"
    exit 1
fi

if [ -z "$(command -v termux-setup-storage)" ]; then
    echo "${red}termux-setup-storage command not found. Please install Termux and try again.${reset}"
    exit 1
fi

msg -n "${blue}Setting up storage permissions...${reset}"
termux-setup-storage
if [ $? -ne 0 ]; then
  msg "${red}Failed to set up storage permissions. Please check your Termux installation.${reset}"
else
  msg "${green}Storage permissions set up successfully!${reset}"
fi

msg -n "${yellow}Installing proot-distro...${reset}"
pkg install -y proot-distro > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "${red}Failed to install proot-distro. Please check your package manager.${reset}"
  exit 1
fi
msg "${green}proot-distro installed successfully!${reset}"

if [ "$install_type" == "gui" ]; then
    msg -n "${green}Installing GUI dependencies...${reset}"
    pkg install -y x11-repo > /dev/null 2>&1
    pkg install -y xorg-server xorg-xrandr termux-x11-nightly pulseaudio > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install GUI dependencies. Please check your package manager.${reset}"
        exit 1
    fi
    msg "${green}GUI dependencies installed successfully!${reset}"
fi

INSTALL_DIR=$PREFIX/var/lib/proot-distro/installed-rootfs
if [ ! -d "$INSTALL_DIR" ]; then
    echo "${red}Installation directory $INSTALL_DIR does not exist. Please check your Termux installation.${reset}"
    exit 1
fi

read -p "Choose a distribution to install [ debian, ubuntu, fedora, alpine, archlinux, void ] (press enter for debian): " distro
distro=${distro:-debian}

if [ "$distro" != "debian" ] && [ "$distro" != "ubuntu" ] && [ "$distro" != "fedora" ] && [ "$distro" != "alpine" ] && [ "$distro" != "archlinux" ] && [ "$distro" != "void" ]; then
    echo "${red}Invalid distribution. Please choose 'debian', 'ubuntu', 'fedora', 'alpine', 'archlinux', or 'void'.${reset}"
    exit 1
fi

if [ ! -d $INSTALL_DIR/$distro ];then
    proot-distro install $distro > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install $distro. Please check your proot-distro installation.${reset}"
        exit 1
    fi
else
    echo "${green}$distro is already installed.${reset}"

    read -p "Do you want to reinstall $distro? [y/n] (press enter for n): " reinstall
    reinstall=${reinstall:-n}
    if [ "$reinstall" != "y" ] && [ "$reinstall" != "n" ]; then
        echo "${red}Invalid choice. Please choose 'y' or 'n'.${reset}"
        exit 1
    fi

    if [ "$reinstall" == "y" ]; then
        read -p "Do you want backup your current $distro installation? [y/n] (press enter for n): " backup
        backup=${backup:-n}
        if [ "$backup" != "y" ] && [ "$backup" != "n" ]; then
            echo "${red}Invalid choice. Please choose 'y' or 'n'.${reset}"
            exit 1
        fi

        if [ "$backup" == "y" ]; then
            echo "${blue}Backing up $distro...${reset}"
            #  proot-distro backup $distro --output-file $HOME/${distro}_backup_$(date +%Y%m%d_%H%M%S).xbackup > /dev/null 2>&1
            tar -czf $HOME/${distro}_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C $INSTALL_DIR $distro > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "${red}Failed to backup $distro. Please check your storage permissions.${reset}"
                exit 1
            fi
            echo "${green}$distro backup completed successfully!${reset}"
        fi

        echo "${yellow}Reinstalling $distro...${reset}"
        proot-distro remove $distro > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${red}Failed to remove $distro. Please check your proot-distro installation.${reset}"
            exit 1
        fi
        proot-distro install $distro > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "${red}Failed to reinstall $distro. Please check your proot-distro installation.${reset}"
            exit 1
        fi
    fi
fi

msg "${green}$distro installation completed successfully!${reset}"

echo "${yellow}Initializing $distro...${reset}"
proot-distro login $distro --shared-tmp -- /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/${install_type}.sh)"
if [ $? -ne 0 ]; then
  echo "${red}Failed to initialize $distro. Please check your proot-distro installation.${reset}"
  exit 1
fi

echo "${blue}You can now start your distribution with the following command:${reset}"
echo "${cyan}proot-distro login $distro${reset}"

if [ -z "$(command -v iqos)" ]; then
    msg -n "${yellow}Installing iqos...${reset}"
    curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/iqos.bash -o $PREFIX/bin/iqos > /dev/null 2>&1
    chmod +x $PREFIX/bin/iqos
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install iqos. Please check your permissions.${reset}"
        exit 1
    fi
    msg "${green}iqos installed successfully!${reset}"
else
    echo "${green}iqos is already installed.${reset}"
fi

sleep 2
exit 0