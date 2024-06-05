#!/bin/bash

# Rabbit TRSS Yunzai 安装脚本 - Windows
NAME=v1.0.0;VERSION=202306010
R="\033[1;31m" G="\033[1;32m" Y="\033[1;33m" C="\033[1;36m" B="\033[m" O="\033[m"

abort() { echo -e "$R! $@$O"; exit 1; }

export LANG=zh_CN.UTF-8

DIR="${DIR:-$HOME/Yunzai}"
CMD="${CMD:-rabbit}"
CMDPATH="${CMDPATH:-/usr/local/bin}"

echo -e "$B————————————————————————————
$R Rabbit$Y TRSS$G Yunzai$C Install$O Script
     $G$NAME$C ($VERSION)$O
$B————————————————————————————
      $G作者：$C重装小兔 🐰$O
"

echo -e "$G 欢迎使用 Rabbit-TRSS-Yunzai ! 作者：重装小兔 🐰$O"

# 初始化 pacman 密钥
echo -e "$Y- 正在初始化 pacman 密钥$O"
pacman-key --init
pacman-key --populate archlinux

# 更新 CA 证书
echo -e "$Y- 正在更新 CA 证书$O"
pacman -Syy archlinux-keyring
pacman -Syu ca-certificates --noconfirm

abort_update() { echo -e "$R! $@$O"; [ "$N" -lt 10 ] && { ((N++)); download; } || abort "脚本下载失败，请检查网络，并尝试重新下载"; }

download() {
  case "$N" in
    1) Server="Gitee" URL="https://gitee.com/OvertimeBunny/Rabbit-TRSS-Yunzai/raw/main";;
    2) Server="GitHub" URL="https://github.com/OvertimeBunny/Rabbit-TRSS-Yunzai/raw/main";;
  esac

  echo -e "$Y- 正在从 $Server 服务器 下载版本信息$O"
  GETVER="$(curl -kL --retry 2 --connect-timeout 5 "$URL/version" 2>/dev/null)" || abort_update "下载失败"
  NEWVER="$(sed -n s/^version=//p<<<"$GETVER")"
  NEWNAME="$(sed -n s/^name=//p<<<"$GETVER")"
  NEWMD5="$(sed -n s/^md5=//p<<<"$GETVER")"
  [ -n "$NEWVER" ] && [ -n "$NEWNAME" ] && [ -n "$NEWMD5" ] || abort_update "下载文件版本信息缺失"
  
  echo -e "$B  最新版本：$G$NEWNAME$C ($NEWVER)$O"
  echo -e "$Y  开始下载$O"
  
  mkdir -vp "$DIR" && curl -kL --retry 2 --connect-timeout 5 "$URL/Main.sh" > "$DIR/Main.sh" || abort_update "下载失败"
  [ "$(md5sum "$DIR/Main.sh" | head -c 32)" = "$NEWMD5" ] || abort_update "下载文件校验错误"
  
  mkdir -vp "$CMDPATH" && echo -n "exec bash '$DIR/Main.sh' "'"$@"' > "$CMDPATH/$CMD" && chmod 755 "$CMDPATH/$CMD" || abort "脚本执行命令 $CMDPATH/$CMD 设置失败，手动执行命令：bash '$DIR/Main.sh'"
  
  echo -e "$G- 脚本安装完成，启动命令：$C$CMD$O"
  exit
}

# 检查并安装依赖
check_and_install_deps() {
  echo -e "$Y- 为你安装相关依赖，请稍等$O"
  pacman -Syu --noconfirm nodejs redis git npm yarn openjdk-11-jdk python ffmpeg make gcc nano patch pyenv python-pip sqlite fish
  npm install -g pnpm
}

install_yunzai() {
  echo -e "$Y- 正在为你安装TRSS崽$O"
  git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai $DIR || {
    echo -e "$Y- Gitee下载失败，尝试切换到GitHub$O"
    git clone --depth 1 https://github.com/TimeRainStarSky/Yunzai $DIR || {
      echo -e "$R! 你这破网是怎么回事！$O"
      exit 1
    }
  }
  cd $DIR
  pnpm install
}

install_plugins() {
  echo -e "$Y- 正在为你安装基础插件：TRSS-Plugin、Miao-Plugin、Guoba-Plugin$O"
  git clone --depth 1 https://gitee.com/OvertimeBunny/trss-plugin.git plugins/TRSS-Plugin
  cd plugins/TRSS-Plugin && pnpm install && cd ..

  git clone --depth=1 https://gitee.com/yoimiya-kokomi/miao-plugin.git plugins/miao-plugin
  cd plugins/miao-plugin && pnpm install && cd ..

  git clone --depth=1 https://gitee.com/guoba-yunzai/guoba-plugin.git plugins/Guoba-Plugin
  cd plugins/Guoba-Plugin && pnpm install && cd ..
}

configure_yunzai() {
  echo -e "$Y- 正在启动并配置 Yunzai$O"
  node app &
  sleep 5
  echo -e "$Y- 加载配置文件$O"
  if [ -d "$DIR/data" ]; then
    echo -e "$Y- 监听文件位置：Yunzai/data$O"
  else
    echo -e "$R! Yunzai/data 文件加载失败$O"
    exit 1
  fi
  kill %1
}

main_menu() {
  trap 'main_menu' SIGINT

  clear
  echo -e "$Y- 回来了小老弟？给你检查一下依赖$O"
  cd $DIR
  pnpm update
  pnpm install

  echo '请选择你需要的适配器：'
  echo '1：QQBot（官方机器人）'
  echo '2：ICQQ（普通机器人）'
  echo '3：NTQQ'
  read -p '选择一个选项: ' adapter_choice

  case $adapter_choice in
    1) configure_qqbot ;;
    2) configure_icqq ;;
    3) configure_ntqq ;;
    *) echo '无效选项'; main_menu ;;
  esac
}

configure_qqbot() {
  if ! git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai-QQBot-Plugin plugins/QQBot-Plugin; then
    echo -e "$Y- Gitee下载失败，尝试切换到GitHub$O"
    if ! git clone --depth 1 https://github.com/TimeRainStarSky/Yunzai-QQBot-Plugin plugins/QQBot-Plugin; then
      echo -e "$R! 你这破网是怎么回事！$O"
      exit 1
    fi
  fi

  node app &
  sleep 5
  if [ -f "$DIR/config/QQBot.yaml" ]; then
    echo -e "$Y- 监听文件位置：Yunzai/config/QQBot.yaml$O"
  else
    echo -e "$R! Yunzai/config/QQBot.yaml 文件加载失败$O"
    exit 1
  fi

  kill %1

  read -p '输入你的官方机器人QQ: ' bot_qq
  read -p '输入你的官方机器人ID: ' bot_id
  read -p '输入你的官方机器人Token: ' bot_token
  read -p '输入你的官方机器人AppSecret: ' bot_secret

  echo '是否有群权限（使用↑↓控制）'
  select bot_group in 是 不是; do
    if [ "$bot_group" == "是" ]; then
      bot_group=1
    else
      bot_group=0
    fi
    break
  done

  echo '是否公域（使用↑↓控制）'
  select bot_public in 是 不是; do
    if [ "$bot_public" == "是" ]; then
      bot_public=0
    else
      bot_public=1
    fi
    break
  done

  cat > $DIR/config/QQBot.yaml <<EOF
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

configure_icqq() {
  if ! git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai-ICQQ-Plugin plugins/ICQQ-Plugin; then
    echo -e "$Y- Gitee下载失败，尝试切换到GitHub$O"
    if ! git clone --depth 1 https://github.com/TimeRainStarSky/Yunzai-ICQQ-Plugin plugins/ICQQ-Plugin; then
      echo -e "$R! 你这破网是怎么回事！$O"
      exit 1
    fi
  fi

  node app &
  sleep 5
  if [ -f "$DIR/config/ICQQ.yaml" ]; then
    echo -e "$Y- 监听文件位置：Yunzai/config/ICQQ.yaml$O"
  else
    echo -e "$R! Yunzai/config/ICQQ.yaml 文件加载失败$O"
    exit 1
  fi

  kill %1

  echo -e "$Y- 正在检查ICQQ签名$O"
  sign_urls=('https://hlhs-nb.cn/signed/?key=114514' 'http://1.QSign.icu?key=XxxX' 'http://2.QSign.icu?key=XxxX' 'http://3.QSign.icu?key=XxxX' 'http://4.QSign.icu?key=XxxX' 'http://5.QSign.icu?key=XxxX')

  min_latency=9999
  selected_url=''

  for url in ${sign_urls[@]}; do
    start_time=$(date +%s%N)
    curl -o /dev/null -s $url
    end_time=$(date +%s%N)
    latency=$(( (end_time - start_time) / 1000000 ))

    if [ $latency -lt $min_latency ]; then
      min_latency=$latency
      selected_url=$url
    fi
  done

  echo -e "$Y- 已选签名${selected_url}，延迟${min_latency}ms，正在配置$O"

  cat > $DIR/config/ICQQ.yaml <<EOF
tips:
  - 欢迎使用 TRSS-Yunzai ICQQ Plugin ! 作者：时雨🌌星空
  - 参考：https://github.com/TimeRainStarSky/Yunzai-ICQQ-Plugin
permission: master
markdown:
  mode: false
  button: false
  callback: true
bot:
  sign_api_addr: $selected_url
token: []
EOF

  read -p '请输入你机器人的QQ: ' bot_qq
  read -p '请输入你机器人的QQ密码: ' bot_password

  cat >> $DIR/config/ICQQ.yaml <<EOF
  - $bot_qq:$bot_password:2
EOF

  node app &
}

configure_ntqq() {
  if ! git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai-Lagrange-Plugin plugins/Lagrange-Plugin; then
    echo -e "$Y- Gitee下载失败，尝试切换到GitHub$O"
    if ! git clone --depth 1 https://github.com/TimeRainStarSky/Yunzai-Lagrange-Plugin plugins/Lagrange-Plugin; then
      echo -e "$R! 你这破网是怎么回事！$O"
      exit 1
    fi
  fi

  node app &
  sleep 5
  if [ -f "$DIR/config/Lagrange.yaml" ]; then
    echo -e "$Y- 监听文件位置：Yunzai/config/Lagrange.yaml$O"
  else
    echo -e "$R! Yunzai/config/Lagrange.yaml 文件加载失败$O"
    exit 1
  fi

  kill %1

  echo -e "$Y- 启动测试成功，正在为你配置签名$O"

  cat > $DIR/config/Lagrange.yaml <<EOF
tips:
  - 欢迎使用 TRSS-Yunzai Lagrange Plugin ! 作者：时雨🌌星空
  - 参考：https://github.com/TimeRainStarSky/Yunzai-Lagrange-Plugin
permission: master
markdown:
  mode: false
  button: false
  callback: true
bot:
  signApiAddr: https://sign.libfekit.so/api/sign
token: []
EOF

  read -p '请输入你机器人的QQ账号: ' bot_qq
  read -p '请输入你机器人的QQ密码: ' bot_password

  cat >> $DIR/config/Lagrange.yaml <<EOF
  - $bot_qq:$bot_password
EOF

  node app &
}

echo -e "$Y- 正在下载脚本$O"
N=1
download

# 安装依赖
check_and_install_deps

# 安装Yunzai
install_yunzai

# 安装插件
install_plugins

# 配置Yunzai
configure_yunzai

# 启动主菜单
main_menu
