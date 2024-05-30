#!/bin/bash

# tested on ubuntu 22.04

print_stage() {
  echo -e "\033[31m[STAGE $1] $2\033[0m"
}
error() {
    echo -e "\033[31m[ERROR] $1\033[0m"
    exit 1
}

print_stage 1 "Install OhMyZsh"
sudo apt install zsh
sh -c "$(wget -O- https://install.ohmyz.sh/)"


print_stage 2 "(Plugin) autojump"
sudo apt install autojump
if [[ -s /usr/share/autojump/autojump.sh ]]; then
    echo '# oh-my-zsh setup' >> ~/.zshrc
    echo '. /usr/share/autojump/autojump.sh' >> ~/.zshrc
else
    error "autojump not found, check platform compatibility."
fi
