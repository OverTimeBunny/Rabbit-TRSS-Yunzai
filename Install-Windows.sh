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

echo -e "$Y- 正在下载脚本$O"
N=1
download
