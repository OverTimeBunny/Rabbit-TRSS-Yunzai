#!/bin/bash

# Rabbit-TRSS-Yunzai 安装脚本 作者：重装小兔 🐰
NAME=v1.0.0; VERSION=202306010
R="\033[1;31m" G="\033[1;32m" Y="\033[1;33m" C="\033[1;36m" B="\033[m" O="\033[m"

echo -e "$B————————————————————————————
$R Rabbit$Y TRSS$G Yunzai$C Install$O Script
     $G$NAME$C ($VERSION)$O
$B————————————————————————————
      $G作者：$C重装小兔 🐰$O"

abort() {
  echo -e "$R! $@$O"
  exit 1
}

export LANG=zh_CN.UTF-8
[ "$(uname)" = Linux ] || export MSYS=winsymlinks

DIR="${DIR:-$HOME/Yunzai}"
CMD="${CMD:-rabbit}"
CMDPATH="${CMDPATH:-/usr/local/bin}"

# 更换清华大学源
echo -e "$Y- 正在更换清华大学源$O"
cat > /etc/pacman.d/mirrorlist <<EOF
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/\$repo
Server = https://mirrors.ustc.edu.cn/msys2/msys/\$repo
EOF

type pacman &>/dev/null || abort "找不到 pacman 命令，请确认安装了正确的 Arch Linux 环境"
type curl dialog git &>/dev/null || {
  echo -e "$Y- 正在安装依赖$O"
  pacman -Syu --noconfirm --needed --overwrite "*" curl dialog git || abort "依赖安装失败"
}

# 更新密钥环并安装依赖
echo -e "$Y- 正在更新密钥环并安装依赖$O"
pacman-key --init
pacman-key --populate msys2
pacman -Syyu --noconfirm
pacman -S --noconfirm mingw-w64-x86_64-nodejs mingw-w64-x86_64-npm
npm install -g npm
npm install -g pnpm

abort_update() {
  echo -e "$R! $@$O"
  [ "$N" -lt 10 ] && {
    ((N++))
    download
  } || abort "脚本下载失败，请检查网络，并尝试重新下载"
}

download() {
  case "$N" in
  1)
    Server="Gitee"
    URL="https://gitee.com/TimeRainStarSky/Yunzai"
    ;;
  2)
    Server="GitHub"
    URL="https://github.com/TimeRainStarSky/Yunzai"
    ;;
  esac
  echo -e "\n  正在从 $Server 服务器 下载文件"
  git clone --depth 1 "$URL" "$DIR" || abort_update "下载失败"
}

echo -e "\n$Y- 正在下载脚本$O"
N=1
download

echo -e "$Y- 安装项目依赖$O"
cd "$DIR" || abort "目录不存在：$DIR"
npm install || abort "项目依赖安装失败"

echo -e "$Y- 安装插件$O"
cd plugins
git clone --depth 1 https://gitee.com/OvertimeBunny/trss-plugin.git TRSS-Plugin
cd TRSS-Plugin && npm install && cd ..

git clone --depth 1 https://gitee.com/yoimiya-kokomi/miao-plugin.git miao-plugin
cd miao-plugin && npm install && cd ..

git clone --depth 1 https://gitee.com/guoba-yunzai/guoba-plugin.git guoba-plugin
cd guoba-plugin && npm install && cd ..

echo -e "$G- 插件安装完成，即将启动Yunzai$O"
node app &
sleep 5

echo -e "$Y- 加载配置文件$O"
if [ -d "$DIR/data" ]; then
  echo -e "$Y- 监听文件位置：$DIR/data$O"
else
  echo -e "$R! 配置文件加载失败$O"
  exit 1
fi

kill %1

trap 'Main_Menu' SIGINT

Main_Menu() {
  clear
  echo -e "$Y- 回来了小老弟？给你检查一下依赖$O"
  cd "$DIR" || abort "目录不存在：$DIR"
  npm update
  npm install

  echo "请选择你需要的适配器："
  echo "1：QQBot（官方机器人）"
  echo "2：ICQQ（普通机器人）"
  echo "3：NTQQ"
  read -p "选择一个选项: " adapter_choice

  case $adapter_choice in
  1) Configure_QQBot ;;
  2) Configure_ICQQ ;;
  3) Configure_NTQQ ;;
  *) echo "无效选项"
    Main_Menu
    ;;
  esac
}

Configure_QQBot() {
  git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai-QQBot-Plugin plugins/QQBot-Plugin || abort_update "下载失败"
  node app &
  sleep 5
  [ -f "$DIR/config/QQBot.yaml" ] || abort "配置文件加载失败：$DIR/config/QQBot.yaml"
  kill %1

  read -p "输入你的官方机器人QQ: " bot_qq
  read -p "输入你的官方机器人ID: " bot_id
  read -p "输入你的官方机器人Token: " bot_token
  read -p "输入你的官方机器人AppSecret: " bot_secret

  echo "是否有群权限（使用↑↓控制）"
  select bot_group in 是 不是; do
    bot_group=$( [ "$bot_group" == "是" ] && echo 1 || echo 0 )
    break
  done

  echo "是否公域（使用↑↓控制）"
  select bot_public in 是 不是; do
    bot_public=$( [ "$bot_public" == "是" ] && echo 0 || echo 1 )
    break
  done

  echo "是否开启/转#（使用↑↓控制）"
  select bot_convert in 开启 关闭; do
    bot_convert=$( [ "$bot_convert" == "开启" ] && echo true || echo false )
    break
  done

  echo "请选择公网IP获取方式："
  echo "1：手动输入"
  echo "2：自动获取"
  read -p "选择一个选项: " ip_choice

  case $ip_choice in
  1)
    read -p "请输入你的公网IP: " public_ip
    ;;
  2)
    public_ip=$(curl -s ifconfig.me)
    echo "自动获取的公网IP为：$public_ip"
    ;;
  *)
    echo "无效选项"
    Main_Menu
    ;;
  esac

  sed -i "s#url:.*#url: http://$public_ip:2536#" "$DIR/config/config/bot.yaml"
  sed -i "s#/→#:#/→#: $bot_convert#" "$DIR/config/config/bot.yaml"

  cat >"$DIR/config/QQBot.yaml" <<EOF
tips:
  - 欢迎使用 TRSS-Yunzai QQBot Plugin ! 作者：时雨🌌星空
  - 参考：https://github.com/TimeRainStarSky/Yunzai-QQBot-Plugin
permission: master
toQRCode: true
toCallback: true
toBotUpload: true
hideGuildRecall: false
markdown:
  template: abcdefghij
bot:
  sandbox: false
  maxRetry: .inf
  timeout: 30000
token:
  - $bot_qq:$bot_id:$bot_token:$bot_secret:$bot_group:$bot_public
EOF

  node app &
}

Configure_ICQQ() {
  git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai-ICQQ-Plugin plugins/ICQQ-Plugin || abort_update "下载失败"
  node app &
  sleep 5
  [ -f "$DIR/config/ICQQ.yaml" ] || abort "配置文件加载失败：$DIR/config/ICQQ.yaml"
  kill %1

  echo -e "$Y- 正在检查ICQQ签名$O"
  sign_urls=('https://hlhs-nb.cn/signed/?key=114514' 'http://1.QSign.icu?key=XxxX' 'http://2.QSign.icu?key=XxxX' 'http://3.QSign.icu?key=XxxX' 'http://4.QSign.icu?key=XxxX' 'http://5.QSign.icu?key=XxxX')

  min_latency=9999
  selected_url=''

  for url in "${sign_urls[@]}"; do
    start_time=$(date +%s%N)
    curl -o /dev/null -s "$url"
    end_time=$(date +%s%N)
    latency=$(( (end_time - start_time) / 1000000 ))
    if [ $latency -lt $min_latency ]; then
      min_latency=$latency
      selected_url=$url
    fi
  done

  echo "最佳签名地址：$selected_url"

  read -p "输入你的ICQQ QQ: " icqq_qq
  read -p "输入你的ICQQ Token: " icqq_token

  cat >"$DIR/config/ICQQ.yaml" <<EOF
icqq:
  account: $icqq_qq
  token: $icqq_token
  sign_url: $selected_url
EOF

  node app &
}

Main_Menu
