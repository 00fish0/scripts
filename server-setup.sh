#!/bin/bash

# Untested

server=""
network_account=""
startup_sec="10s"
pub_key=""

CACHE_ROOT=/tmp/deploy_cache
STAGE=-1
TOT_STAGE=5


function error() {
    echo -e "\033[31m[ERROR] $1\033[0m" >&2
    exit 1
}
function log() {
  echo -e "\033[32m[LOG] $1\033[0m"
}

function print_stage() {
  log "Stage $1: $2"
  update_stage
}
function update_stage() {
	STAGE=$(($STAGE + 1))
	echo $STAGE >$CACHE_ROOT/stage
}

# cat ~/.ssh/id_rsa.pub | ssh $server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

function stage_0() {
  print_stage 0 "ssh passwordless login"

  cat << EOF >> ~/.ssh/authorized_keys
$pub_key
EOF
}

function stage_1() {
#   print_stage 1 "Setup School Network Login Script"

#   mkdir -p ~/auto_login
#   wget -P ~/auto_login https://github.com/hstable/SRUN_LOGIN/releases/download/v1.1.1/SRUN_LOGIN_linux_arm -O ~/auto_login/SRUN_LOGIN

#   cd ~/auto_login || error "cd failed"
#   cat << 'EOF' > login.sh # here-document
# echo "[LOG] $(date '+%Y-%m-%d %H:%M:%S')" >> ~/auto_login/login.log
# ~/auto_login/SRUN_LOGIN $network_account >> ~/auto_login/login.log 2>&1
# EOF
}

function stage_2() {
#   print_stage 2 "Create system service & timer"

#   cat << 'EOF' > /etc/systemd/system/srun_login.service
# [Unit]
# Description=login school-net

# [Service]
# ExecStart=sudo /bin/bash ~/auto_login/login.sh
# EOF

#   cat << EOF > /etc/systemd/system/srun_login.timer  # if login fails with network setup error, increase OnStartupSec below.
# [Unit]
# Description=Runs login school-net script timer

# [Timer]
# OnStartupSec=$startup_sec
# Unit=srun_login.service

# [Install]
# WantedBy=multi-user.target
# EOF

#   sudo systemctl enable srun_login.timer
}

function stage_3() {
  print_stage 3 "Change mirror website to HITSZ"

  if grep -q 'ubuntu' /etc/os-release; then
    log "Ubuntu detected."
    cat <<'EOF' > /etc/apt/sources.list
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.osa.moe/ubuntu/ jammy main restricted universe multiverse
# deb-src https://mirrors.osa.moe/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.osa.moe/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src https://mirrors.osa.moe/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.osa.moe/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src https://mirrors.osa.moe/ubuntu/ jammy-backports main restricted universe multiverse

# deb https://mirrors.osa.moe/ubuntu/ jammy-security main restricted universe multiverse
# # deb-src https://mirrors.osa.moe/ubuntu/ jammy-security main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.osa.moe/ubuntu/ jammy-proposed main restricted universe multiverse
# # deb-src https://mirrors.osa.moe/ubuntu/ jammy-proposed main restricted universe multiverse
EOF
  elif grep -q 'debian' /etc/os-release; then
    log "Debian detected."
    cat <<'EOF' > /etc/apt/sources.list
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.osa.moe/debian/ bookworm main contrib non-free non-free-firmware
# deb-src https://mirrors.osa.moe/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.osa.moe/debian/ bookworm-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.osa.moe/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.osa.moe/debian/ bookworm-backports main contrib non-free non-free-firmware
# deb-src https://mirrors.osa.moe/debian/ bookworm-backports main contrib non-free non-free-firmware

# deb https://mirrors.osa.moe/debian-security bookworm-security main contrib non-free non-free-firmware
# # deb-src https://mirrors.osa.moe/debian-security bookworm-security main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
  else
    error "Unsupported OS."
  fi
}

function stage_4() {
  print_stage 4 "Update & Upgrade & Download Basic tools"

  sudo apt update
  sudo apt install git tmux vim -y
  sudo apt upgrade -y
}

function stage_5() {
  print_stage 5 "Install OhMyZsh"

  sudo apt install zsh -y
  sh -c "$(wget -O- https://install.ohmyz.sh/)"

  log "Installing plugin autojump..."

  sudo apt install autojump
  if [[ -s /usr/share/autojump/autojump.sh ]]; then
    echo '# oh-my-zsh setup' >> ~/.zshrc
    echo '. /usr/share/autojump/autojump.sh' >> ~/.zshrc
  else
    error "autojump not found, check platform compatibility."
  fi
}

function stage_6() {
  print_stage 6 "Dotfiles"

  rm {~/.vimrc,~/.gitconfig,~/.tmux.conf}

  # cd ~/auto_login || error "cd failed"
  # git clone -b server https://github.com/00fish0/dotfiles.git
  # ./dotfiles/setup.sh
  cat << 'EOF' > ~/.tmux.conf
set -g prefix C-a
 
unbind C-b
 
bind C-a send-prefix
EOF

  cat << 'EOF' > ~/.vimrc
" All system-wide defaults are set in $VIMRUNTIME/debian.vim and sourced by
" the call to :runtime you can find below.  If you wish to change any of those
" settings, you should do it in this file (/etc/vim/vimrc), since debian.vim
" will be overwritten everytime an upgrade of the vim packages is performed.
" It is recommended to make changes after sourcing debian.vim since it alters
" the value of the 'compatible' option.

runtime! debian.vim

" Vim will load $VIMRUNTIME/defaults.vim if the user does not have a vimrc.
" This happens after /etc/vim/vimrc(.local) are loaded, so it will override
" any settings in these files.
" If you don't want that to happen, uncomment the below line to prevent
" defaults.vim from being loaded.
" let g:skip_defaults_vim = 1

" Uncomment the next line to make Vim more Vi-compatible
" NOTE: debian.vim sets 'nocompatible'.  Setting 'compatible' changes numerous
" options, so any other options should be set AFTER setting 'compatible'.
"set compatible

" Vim5 and later versions support syntax highlighting. Uncommenting the next
" line enables syntax highlighting by default.
if has("syntax")
  syntax on
endif

" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
"set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
"au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
filetype plugin indent on

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
"set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set smartcase		" Do smart case matching
set incsearch		" Incremental search
"set autowrite		" Automatically save before commands like :next and :make
set hidden		" Hide buffers when they are abandoned
"set mouse=a		" Enable mouse usage (all modes)

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif
EOF

  cat << 'EOF' > ~/.gitconfig
[user]
	email = tzh2005t@163.com
	name = tzh

[alias]
lg1 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all
lg2 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all
lg = !"git lg1"
EOF

}

function branch_continue() {
  mkdir -p $CACHE_ROOT
  if [ -f "$CACHE_ROOT/stage" ]; then
    STAGE=$(cat $CACHE_ROOT/stage)
    log "Continue from stage $STAGE"
    STAGE=$(($STAGE - 1))
  fi

  ## continue from the next stage
  for ((i = $(($STAGE + 1)); i <= $TOT_STAGE; i++)); do
    stage_$i
  done
}

function main() {

  if [ "$(id -u)" != "0" ]; then
    error "This script must be run as root"
    return 1
  fi

  if [ $# -gt 1 ]; then
    error "0/1 argument expected.\nUsage: $0 [clear|all] ..."
    return 1
  fi

  if [ $# -eq 1 ]; then
    case "$1" in
      clear)
        # 添加清理逻辑
        log "Clearing..."
        rm -r $CACHE_ROOT
        ;;
      all)
        # 添加执行所有阶段的逻辑
        log "Forcing to execute all stages..."
        rm -r $CACHE_ROOT
        branch_continue
        ;;
      *)
        # 如果传入未知参数，显示错误消息
        error "Unknown argument '$1'.\nUsage: $0 [clear|all]"
        return 1
        ;;
    esac
  else
    branch_continue
  fi
}

main "$@"