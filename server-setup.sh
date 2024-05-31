#!/bin/bash

# Untested

server="pi@10.250.116.205"
network_account="2023311B21 tzh20050911"
startup_sec="10s"

print_stage() {
  echo -e "\033[31m[STAGE $1] $2\033[0m"
}
error() {
    echo -e "\033[31m[ERROR] $1\033[0m"
    exit 1
}
log() {
  echo -e "\033[32m[LOG] $1\033[0m"
}
# cat ~/.ssh/id_rsa.pub | ssh $server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"


print_stage 1 "Setup School Network Login Script"


mkdir -p ~/auto_login
wget -P ~/auto_login https://github.com/hstable/SRUN_LOGIN/releases/download/v1.1.1/SRUN_LOGIN_linux_arm -O SRUN_LOGIN

cd ~/auto_login || error "cd failed"
cat << EOF > login.sh # here-document
echo "[LOG] $(date '+%Y-%m-%d %H:%M:%S')" >> ~/auto_login/login.log
~/auto_login/SRUN_LOGIN $network_account >> ~/auto_login/login.log 2>&1
EOF


print_stage 2 "Create system service & timer"


cat << EOF | sudo tee /etc/systemd/system/srun_login.service > /dev/null
[Unit]
Description=login school-net

[Service]
ExecStart=sudo /bin/bash ~/auto_login/login.sh
EOF

cat << EOF | sudo tee /etc/systemd/system/srun_login.timer > /dev/null # if login fails with network setup error, increase OnStartupSec below.
[Unit]
Description=Runs login school-net script timer

[Timer]
OnStartupSec=$startup_sec
Unit=srun_login.service

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable srun_login.timer


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

print_stage 4 "Update & Upgrade"

sudo apt update
sudo apt upgrade