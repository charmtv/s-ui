#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)
repo="${SUI_REPO:-charmtv/s-ui}"
fallback_repo="alireza0/s-ui"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain}请使用 root 权限运行此脚本\n" && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "无法识别当前操作系统，请检查系统环境。" >&2
    exit 1
fi
echo "当前系统：$release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${red}不支持当前 CPU 架构。${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "系统架构：$(arch)"

install_base() {
    case "${release}" in
    centos | almalinux | rocky | oracle)
        yum -y update && yum install -y -q wget curl tar
        ;;
    fedora)
        dnf -y update && dnf install -y -q wget curl tar
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar
        ;;
    *)
        apt-get update && apt-get install -y -q wget curl tar
        ;;
    esac
}

config_after_install() {
    echo -e "${yellow}正在迁移数据库...${plain}"
    /usr/local/s-ui/sui migrate
    
    echo -e "${yellow}安装或更新完成。建议立即修改面板配置。${plain}"
    read -p "是否现在配置面板？[y/n]：" config_confirm
    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
        echo -e "请输入${yellow}面板端口${plain}（留空使用当前值或默认值）："
        read config_port
        echo -e "请输入${yellow}面板路径${plain}（留空使用当前值或默认值）："
        read config_path

        # Sub configuration
        echo -e "请输入${yellow}订阅端口${plain}（留空使用当前值或默认值）："
        read config_subPort
        echo -e "请输入${yellow}订阅路径${plain}（留空使用当前值或默认值）："
        read config_subPath

        # Set configs
        echo -e "${yellow}正在保存配置，请稍候...${plain}"
        params=""
        [ -z "$config_port" ] || params="$params -port $config_port"
        [ -z "$config_path" ] || params="$params -path $config_path"
        [ -z "$config_subPort" ] || params="$params -subPort $config_subPort"
        [ -z "$config_subPath" ] || params="$params -subPath $config_subPath"
        /usr/local/s-ui/sui setting ${params}

        read -p "是否修改管理员账号和密码？[y/n]：" admin_confirm
        if [[ "${admin_confirm}" == "y" || "${admin_confirm}" == "Y" ]]; then
            read -p "请输入管理员账号：" config_account
            read -p "请输入管理员密码：" config_password

            # Set credentials
            echo -e "${yellow}正在保存管理员信息，请稍候...${plain}"
            /usr/local/s-ui/sui admin -username ${config_account} -password ${config_password}
        else
            echo -e "${yellow}当前管理员信息：${plain}"
            /usr/local/s-ui/sui admin -show
        fi
    else
        echo -e "${yellow}已跳过面板配置。${plain}"
        if [[ ! -f "/usr/local/s-ui/db/s-ui.db" ]]; then
            local usernameTemp=$(head -c 6 /dev/urandom | base64)
            local passwordTemp=$(head -c 6 /dev/urandom | base64)
            echo -e "检测到全新安装，已自动生成随机登录信息："
            echo -e "###############################################"
            echo -e "${green}账号：${usernameTemp}${plain}"
            echo -e "${green}密码：${passwordTemp}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}如需查看或修改登录信息，请运行 ${green}s-ui${yellow} 打开管理菜单。${plain}"
            /usr/local/s-ui/sui admin -username ${usernameTemp} -password ${passwordTemp}
        else
            echo -e "${yellow}升级已保留原有配置。如需查看登录信息，请运行 ${green}s-ui${yellow}。${plain}"
        fi
    fi
}

prepare_services() {
    if [[ -f "/etc/systemd/system/sing-box.service" ]]; then
        echo -e "${yellow}正在停止 sing-box 服务...${plain}"
        systemctl stop sing-box
        rm -f /usr/local/s-ui/bin/sing-box /usr/local/s-ui/bin/runSingbox.sh /usr/local/s-ui/bin/signal
    fi
    if [[ -e "/usr/local/s-ui/bin" ]]; then
        echo -e "###############################################################"
        echo -e "${green}/usr/local/s-ui/bin${yellow} 目录已存在。"
        echo -e "迁移完成后请检查其内容，并按需手动删除。${plain}"
        echo -e "###############################################################"
    fi
    systemctl daemon-reload
}

install_s-ui() {
    cd /tmp/
    release_repo="$repo"

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/${release_repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" && "$release_repo" != "$fallback_repo" ]]; then
            echo -e "${yellow}当前仓库暂无 Release，临时使用上游发布包。${plain}"
            release_repo="$fallback_repo"
            last_version=$(curl -Ls "https://api.github.com/repos/${release_repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        fi
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}获取最新版本失败，请检查 GitHub 网络连接或稍后重试。${plain}"
            exit 1
        fi
        echo -e "最新版本：${last_version}，开始安装..."
        wget -N --no-check-certificate -O /tmp/s-ui-linux-$(arch).tar.gz "https://github.com/${release_repo}/releases/download/${last_version}/s-ui-linux-$(arch).tar.gz"
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 s-ui 失败，请确认服务器可以访问 GitHub。${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/${release_repo}/releases/download/${last_version}/s-ui-linux-$(arch).tar.gz"
        echo -e "开始安装 s-ui v$1"
        wget -N --no-check-certificate -O /tmp/s-ui-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 && "$release_repo" != "$fallback_repo" ]]; then
            echo -e "${yellow}当前仓库未找到该版本，尝试使用上游发布包。${plain}"
            release_repo="$fallback_repo"
            url="https://github.com/${release_repo}/releases/download/${last_version}/s-ui-linux-$(arch).tar.gz"
            wget -N --no-check-certificate -O /tmp/s-ui-linux-$(arch).tar.gz ${url}
        fi
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 s-ui v$1 失败，请确认该版本已发布。${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/s-ui/ ]]; then
        systemctl stop s-ui
    fi

    tar zxvf s-ui-linux-$(arch).tar.gz
    rm s-ui-linux-$(arch).tar.gz -f

    echo -e "${yellow}正在更新简体中文管理脚本...${plain}"
    curl -fLs "https://raw.githubusercontent.com/charmtv/s-ui/main/s-ui.sh" -o s-ui/s-ui.sh
    if [[ $? -ne 0 ]]; then
        echo -e "${red}下载中文管理脚本失败，请检查 GitHub 网络连接。${plain}"
        exit 1
    fi

    chmod +x s-ui/sui s-ui/s-ui.sh
    cp s-ui/s-ui.sh /usr/bin/s-ui
    cp -rf s-ui /usr/local/
    cp -f s-ui/*.service /etc/systemd/system/
    rm -rf s-ui

    config_after_install
    prepare_services

    systemctl enable s-ui --now

    echo -e "${green}s-ui v${last_version}${plain} 安装完成，服务已启动。"
    echo -e "面板访问地址：${green}"
    /usr/local/s-ui/sui uri
    echo -e "${plain}"
    echo -e ""
    s-ui help
}

echo -e "${green}开始执行安装脚本...${plain}"
install_base
install_s-ui $1
