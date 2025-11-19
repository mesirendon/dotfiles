# Dotfiles

This project streamlines the installation of software and configurations I use
daily. It is tailored to my personal workflow and preferences. Pull requests are
welcome, provided they do not conflict with my personal setup.

## Installation

### Prerequisites

- Git must be installed. On Debian/Ubuntu:

  ```bash
  sudo apt install git -y
  ```

### Setup

1. Clone the repository:

   ```bash
   git clone git@github.com:mesirendon/dotfiles.git ~/.dotfiles
   ```

2. Enter the directory:

   ```bash
   cd ~/.dotfiles
   ```

3. Run the bootstrap script (you may be prompted for your password):

   ```bash
   ./bootstrap.sh
   ```

4. Restart your system:

   ```bash
   sudo reboot
   ```
