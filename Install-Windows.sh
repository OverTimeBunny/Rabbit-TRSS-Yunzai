#!/bin/bash

# Rabbit TRSS Yunzai 安装脚本
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

abort_update() { echo -e "$R! $@$O"; [ "$N" -lt 10 ] && { ((N++)); download; } || abort "你他喵的网络是怎么回事！给我好好检查你的网络环境！"; }

# 检查并安装git
if ! type git &>/dev/null; then
  echo -e "$Y- 正在安装 git$O"
  if type pacman &>/dev/null; then
    pacman -Sy --noconfirm git || abort "git 安装失败"
  elif type apt-get &>/dev/null; then
    apt-get update && apt-get install -y git || abort "git 安装失败"
  else
    abort "找不到合适的包管理器来安装 git"
  fi
fi

download() {
  case "$N" in
    1) Server="Gitee" URL="https://gitee.com/TimeRainStarSky/Yunzai";;
    2) Server="GitHub" URL="https://github.com/TimeRainStarSky/Yunzai";;
  esac

  echo -e "$Y- 正在从 $Server 服务器 下载文件$O"
  if [ -d "$DIR" ]; then
    echo -e "$Y- 删除已有目录：$DIR$O"
    rm -rf "$DIR"
  fi
  mkdir -vp "$DIR" && git clone --depth 1 "$URL" "$DIR" || abort_update "下载失败"
  mkdir -vp "$CMDPATH" && echo -n "cd '$DIR' && node app"' "$@"' > "$CMDPATH/$CMD" && chmod 755 "$CMDPATH/$CMD" || abort "脚本执行命令 $CMDPATH/$CMD 设置失败，手动执行命令：cd '$DIR' && node app"
  if [ -n "$MSYS" ]; then
    type powershell &>/dev/null && powershell -c '$ShortCut=(New-Object -ComObject WScript.Shell).CreateShortcut([System.Environment]::GetFolderPath("Desktop")+"\'"$(basename "$DIR"|tr '_' ' ')"'.lnk")
$ShortCut.TargetPath="'"$(cygpath -w /msys2.exe)"'"
$ShortCut.Arguments="'"$CMD"'"
$ShortCut.Save()'
  else
    type wsl.exe powershell.exe &>/dev/null && powershell.exe -c '$ShortCut=(New-Object -ComObject WScript.Shell).CreateShortcut([System.Environment]::GetFolderPath("Desktop")+"\'"$(basename "$DIR"|tr '_' ' ')"'.lnk")
$ShortCut.TargetPath="'"$(command -v wsl.exe|sed -E 's|/mnt/([a-z]*)/|\1:\\|;s|/|\\|g')"'"
$ShortCut.Arguments="'"$CMD"'"
$ShortCut.Save()'
  fi
  echo -e "$G- 脚本安装完成，启动命令：$C$CMD$O"
  exit
}

N=1
download

# 启动菜单
main_menu() {
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

main_menu
