#!/bin/bash

# tested on ubuntu 22.04
# 执行到oh-my-zsh的时候好像会询问是否更换shell，需要手动输入y，输入之后这个进程似乎被放到后台了
# 不知道如何解决，但是可以重新运行一次脚本。

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
