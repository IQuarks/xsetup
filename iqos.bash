#!/bin/bash

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

display_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --distro    Specify the distribution (e.g., 'ubuntu', 'fedora')"
    echo "  -u, --user      Specify the username for the new user"
    echo "  -s, --shell     Specify the shell to use (e.g., '/bin/bash', '/bin/zsh')"
    echo "  -g, --gui       To start the GUI"
    echo "  --              End of options, pass remaining arguments to the shell"
    echo "  -c, --clear     Clear the current configuration"
    echo "  -h, --help      Show this help message"
}

# Default values
distro=debian
user=""
shell=""
gui=false

if [[ -f "$HOME/.iqos" ]]; then
    source $HOME/.iqos
fi

while [[ $# -ge 1 ]]; do
    case $1 in
        -d|--distro)
            if [[ -z "$2" ]]; then
                echo "${red}Error: ${yellow}--distro${reset} requires a non-empty argument."
                display_usage
                exit 1
            fi

            distro="$2"
            shift 2
            ;;
        -u|--user)
            if [[ -z "$2" ]]; then
                echo "${red}Error: ${yellow}--user${reset} requires a non-empty argument."
                display_usage
                exit 1
            fi
            user="$2"
            shift 2
            ;;
        -s|--shell)
            if [[ -z "$2" ]]; then
                echo "${red}Error: ${yellow}--shell${reset} requires a non-empty argument."
                display_usage
                exit 1
            fi
            shell="$2"
            shift 2
            ;;
        -g|--gui)
            gui=true
            shift
            ;;
        -c|--clear)
            echo "Clearing current configuration..."
            rm -f $HOME/.iqos
            echo "${green}Configuration cleared.${reset}"
            exit 0
            ;;
        -h|--help)
            display_usage
            exit 0
            ;;
        --)
            if $gui; then
                echo "${red}Error: ${yellow}--gui${reset} is not supported with ${yellow}--${reset} option."
                exit 1
            fi
            shift 1
            break
            ;;
        *)
            echo "Unknown option: $1"
            display_usage
            exit 1
            ;;
    esac
done

cat > $HOME/.iqos <<EOF
distro=$distro
user=$user
shell=$shell
EOF

if [[ -n "$shell" ]]; then
    if [[ $# -ge 1 ]]; then
        set -- "--" "$shell" "-c" "$@"
    else
        if ! $gui; then
            set -- "--" "$shell"
        fi
    fi
else
    if [[ $# -ge 1 ]]; then
        set -- "--" "$@"
    fi
fi

if [[ -n "$user" ]]; then
    set -- "--user" "$user" "$@"
fi

if $gui; then
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    proot-distro login $distro --shared-tmp "$@" -- /bin/sh -c "termux-x11 :1 -xstartup \"dbus-launch --exit-with-session xfce4-session\""
    pkill pulseaudio
else
    proot-distro login $distro --shared-tmp "$@"
fi