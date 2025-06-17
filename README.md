# xsetup

This project provides scripts to automate the setup of Termux and the installation of Linux distributions using `proot-distro`. It helps initialize environments for both basic CLI and GUI usage, making it easier to get started with your preferred Linux setup on Android devices.

## Setup Termux

`init.bash` is used to set up Termux and initialize either a CLI or GUI Linux distribution environment.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/init.bash)"
```

## CLI Initialization

To initialize a Linux distribution for CLI usage, use the `cli.sh` script. This script sets up the environment for command-line operations within your chosen distribution.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/cli.sh)"
```

## GUI Initialization

To initialize a Linux distribution for GUI usage with the Xfce4 desktop environment, use the `gui.sh` script. This script sets up your environment for graphical desktop access using Xfce4 within your selected distribution.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/IQuarks/xsetup/main/gui.sh)"
```

## Supported Distributions

Currently, only the following Linux distributions are supported:

- Ubuntu
- Debian
- Alpine
- Fedora
- Arch Linux
- Void Linux

Attempting to use these scripts with other distributions may result in errors or incomplete setup.
