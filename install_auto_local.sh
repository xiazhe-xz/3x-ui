#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# 检查系统版本
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "OS release: $release"

# 检查 CPU 架构
arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    *) echo -e "${red}Unsupported architecture!${plain}" && exit 1 ;;
    esac
}

echo "Arch: $(arch)"

# 检查 GLIBC 版本
check_glibc_version() {
    glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
    required_version="2.32"
    if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${red}GLIBC version $glibc_version is too old! Required: 2.32 or higher${plain}"
        exit 1
    fi
    echo "GLIBC version: $glibc_version (OK)"
}
check_glibc_version

# 安装依赖
install_base() {
    case "${release}" in
    ubuntu | debian) apt-get update && apt-get install -y tar ;;
    centos | almalinux | rocky | ol) yum -y install tar ;;
    fedora) dnf -y install tar ;;
    *) apt-get update && apt-get install -y tar ;;
    esac
}
install_base

# 配置
config_after_install() {
    echo -e "${yellow}Setting default panel configuration...${plain}"

    config_account="admin"
    config_password="Mkp.123456"
    config_port="10000"

    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
    /usr/local/x-ui/x-ui setting -port ${config_port}
    /usr/local/x-ui/x-ui migrate

    echo -e "${yellow}Done! Account: ${config_account} | Password: ${config_password} | Port: ${config_port}${plain}"
}

# 安装 X-UI
install_x-ui() {
    local local_file="/root/x-ui-linux-amd64.tar.gz"

    if [[ ! -f ${local_file} ]]; then
        echo -e "${red}File ${local_file} not found! Please make sure it exists.${plain}"
        exit 1
    fi

    cd /usr/local/

    # 停止旧服务
    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm -rf /usr/local/x-ui/
    fi

    cp ${local_file} ./x-ui-linux-amd64.tar.gz

    tar zxvf x-ui-linux-amd64.tar.gz
    rm -f x-ui-linux-amd64.tar.gz

    cd x-ui
    chmod +x x-ui bin/xray-linux-amd64
    cp -f x-ui.service /etc/systemd/system/

    # 下载启动脚本
    wget -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui

    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui

    echo -e "${green}x-ui installation done! Service is running.${plain}"
}

install_x-ui
