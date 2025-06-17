#!/bn/bash

if [ -z "$(command -v pkg)" ]; then
  echo "pkg command not found. Please install pkg first."
  exit 1
fi

echo "Updating package repository..."
pkg update -f
if [ $? -ne 0 ]; then
  echo "Failed to update package repository. Please check your network connection or package manager."
  exit 1
fi

echo "Upgrading installed packages..."
pkg upgrade -y
if [ $? -ne 0 ]; then
  echo "Failed to upgrade packages. Please check your package manager."
  exit 1
fi

echo "Installing ncurses-utils..."
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

echo "${blue}Setting up storage permissions...${reset}"
termux-setup-storage
if [ $? -ne 0 ]; then
  echo "${red}Failed to set up storage permissions. Please check your Termux installation.${reset}"
  exit 1
fi

echo "${yellow}Installing proot-distro...${reset}"
pkg install -y proot-distro > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "${red}Failed to install proot-distro. Please check your package manager.${reset}"
  exit 1
fi

if [ "$install_type" == "gui" ]; then
    echo "${green}Installing GUI dependencies...${reset}"
    pkg install -y x11-repo > /dev/null 2>&1
    pkg install -y xorg-server xorg-xrandr termux-x11-nightly pulseaudio > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${red}Failed to install GUI dependencies. Please check your package manager.${reset}"
        exit 1
    fi
fi

INSTALL_DIR=$PREFIX/var/lib/proot-distro/installed-rootfs
if [ ! -d "$INSTALL_DIR" ]; then
    echo "${red}Installation directory $INSTALL_DIR does not exist. Please check your Termux installation.${reset}"
    exit 1
fi

read -p "Choose a distribution to install [ debian, ubuntu, fedora, alpine ] (press enter for debian): " distro
distro=${distro:-debian}

if [ "$distro" != "debian" ] && [ "$distro" != "ubuntu" ] && [ "$distro" != "fedora" ] && [ "$distro" != "alpine" ]; then
    echo "${red}Invalid distribution. Please choose 'debian', 'ubuntu', 'fedora', or 'alpine'.${reset}"
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

echo "${green}$distro installation completed successfully!${reset}"

echo "${yellow}Initializing $distro...${reset}"
proot-distro login $distro --shared-tmp -- /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/${install_type}.sh)"
if [ $? -ne 0 ]; then
  echo "${red}Failed to initialize $distro. Please check your proot-distro installation.${reset}"
  exit 1
fi

echo "${blue}You can now start your distribution with the following command:${reset}"
echo "${cyan}proot-distro login $distro${reset}"

sleep 2
exit 0