#!/bin/bash

# TRSS AllBot 安装脚本 作者：重装小兔
NAME=v1.0.0; VERSION=20240606
R="[1;31m"; G="[1;32m"; Y="[1;33m"; C="[1;36m"; B="[m"; O="[m"
echo "$B————————————————————————————
$R TRSS$Y AllBot$G Install$C Script$O
     $G$NAME$C ($VERSION)$O
$B————————————————————————————
      $G作者：$C重装小兔$O
GitHub: https://github.com/OvertimeBunny
Gitee: https://gitee.com/OvertimeBunny
项目仓库地址:
GitHub: https://github.com/OvertimeBunny/Rabbit-TRSS-Yunzai
Gitee: https://gitee.com/OvertimeBunny/Rabbit-TRSS-Yunzai
"

abort() { echo "$R! $@$O"; exit 1; }
export LANG=zh_CN.UTF-8

[ "$(uname)" = Linux ] || export MSYS=winsymlinks
DIR="${DIR:-$HOME/TRSS_AllBot}"
CMD="${CMD:-rabbit}"
CMDPATH="${CMDPATH:-/usr/local/bin}"

type locale-gen &>/dev/null && { 
  echo "$Y- 正在设置语言$O"
  echo "LANG=zh_CN.UTF-8">/etc/locale.conf &&
  sed -i 's/#.*zh_CN\.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen &&
  locale-gen || echo "$R! 语言设置失败$O"
}

type pacman &>/dev/null || abort "找不到 pacman 命令，请确认安装了正确的 Arch Linux 环境"
type curl dialog &>/dev/null || { 
  echo "$Y- 正在安装依赖$O"
  pacman -Syu --noconfirm --needed --overwrite "*" curl dialog || abort "依赖安装失败"
}

abort_update() { echo "$R! $@$O"; [ "$N" -lt 5 ] && { ((N++)); download; } || abort "你他喵的这破网是怎么回事！好好检查一下！"; }

download() {
  case "$N" in
    1) Server="GitHub"; URL="https://gitee.com/OvertimeBunny/Rabbit-TRSS-Yunzai/raw/main/Install-Windows.sh" ;;
    2) Server="Gitee"; URL="https://raw.githubusercontent.com/OvertimeBunny/Rabbit-TRSS-Yunzai/main/Install-Windows.sh" ;;
  esac
  echo "正在从 $Server 服务器 下载版本信息"
  GETVER="$(curl -kL --retry 2 --connect-timeout 5 --insecure "$URL/version" || true)"
  if [ -z "$GETVER" ]; then
    abort_update "下载失败"
  fi
  NEWVER="$(sed -n s/^version=//p<<<"$GETVER")"
  NEWNAME="$(sed -n s/^name=//p<<<"$GETVER")"
  NEWMD5="$(sed -n s/^md5=//p<<<"$GETVER")"
  if [ -z "$NEWVER" ] || [ -z "$NEWNAME" ] || [ -z "$NEWMD5" ]; then
    abort_update "下载文件版本信息缺失"
  fi
  echo "$B  最新版本：$G$NEWNAME$C ($NEWVER)$O"
  echo "开始下载"
  mkdir -vp "$DIR" && curl -kL --retry 2 --connect-timeout 5 --insecure "$URL/Main.sh" > "$DIR/Main.sh" || abort_update "下载失败"
  if [ "$(md5sum "$DIR/Main.sh" | head -c 32)" != "$NEWMD5" ]; then
    abort_update "下载文件校验错误"
  fi
  mkdir -vp "$CMDPATH" && echo -n "exec bash '$DIR/Main.sh' "'"$@"' > "$CMDPATH/$CMD" && chmod 755 "$CMDPATH/$CMD" || abort "脚本执行命令 $CMDPATH/$CMD 设置失败，手动执行命令：bash '$DIR/Main.sh'"
}

echo "$Y- 正在下载脚本$O"
N=1
download

echo "$Y- 正在安装TRSS版本的Yunzai$O"
bash <(clone --depth 1 https://github.com/TimeRainStarSky/Yunzai) || bash <(clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai) || abort "TRSS版本的Yunzai安装失败"

echo "$Y- 正在安装常用插件$O"
PLUGINS=(
  "TRSS-plugin https://github.com/TimeRainStarSky/TRSS-Plugin https://gitee.com/TimeRainStarSky/TRSS-Plugin/"
  "guoba-plugin https://github.com/guoba-yunzai/guoba-plugin https://gitee.com/guoba-yunzai/guoba-plugin"
  "miao-plugin https://github.com/yoimiya-kokomi/miao-plugin https://gitee.com/yoimiya-kokomi/miao-plugin"
)

for PLUGIN in "${PLUGINS[@]}"; do
  NAME="$(echo $PLUGIN | awk '{print $1}')"
  GITHUB_URL="$(echo $PLUGIN | awk '{print $2}')"
  GITEE_URL="$(echo $PLUGIN | awk '{print $3}')"
  echo "$Y- 正在安装插件 $NAME$O"
  git clone "$GITHUB_URL" "$DIR/plugins/$NAME" || git clone "$GITEE_URL" "$DIR/plugins/$NAME" || echo "$R! 插件 $NAME 安装失败$O"
done

echo "$Y- 正在测试启动并监听文件$O"
cd "$DIR"
./start.sh &
PID=$!
sleep 10

if [ -d "$DIR/data" ]; then
  echo "$G- data 文件夹已创建，停止运行$O"
  kill $PID
else
  echo "$R! data 文件夹未创建，检查安装是否成功$O"
  kill $PID
  exit 1
fi

echo "$Y- 监听配置文件正常加载后，自动退出并进入交互页面$O"
CONFIG_FILES=(
  "$DIR/config/config/bot.yaml"
  "$DIR/config/ICQQ.yaml"
  "$DIR/config/Lagrange.yaml"
)

for CONFIG in "${CONFIG_FILES[@]}"; do
  while [ ! -f "$CONFIG" ]; do
    sleep 1
  done
  echo "$G- 配置文件 $CONFIG 已加载$O"
done

# 用户选择适配器
choose_adapter() {
  echo "请选择适配器：
1) QQBot-plugin
2) ICQQ-plugin
3) Lagrange-Plugin
选择后按回车确认："
  read ADAPTER

  case $ADAPTER in
    1) PLUGIN_URL="https://github.com/TimeRainStarSky/Yunzai-QQBot-Plugin"
       CONFIG_FILE="$DIR/config/config/bot.yaml";;
    2) PLUGIN_URL="https://github.com/TimeRainStarSky/Yunzai-ICQQ-Plugin"
       CONFIG_FILE="$DIR/config/ICQQ.yaml";;
    3) PLUGIN_URL="https://github.com/TimeRainStarSky/Yunzai-Lagrange-Plugin"
       CONFIG_FILE="$DIR/config/Lagrange.yaml";;
    *) echo "$R! 无效的选择$O"; exit 1;;
  esac

  echo "$Y- 正在安装适配器$O"
  git clone "$PLUGIN_URL" "$DIR/plugins/$(basename $PLUGIN_URL)"

  echo "$Y- 配置适配器 $O"
  configure_adapter
}

configure_adapter() {
  case $ADAPTER in
    1) configure_qqbot;;
    2) configure_icqq;;
    3) configure_lagrange;;
  esac
}

configure_qqbot() {
  echo "配置 QQBot-plugin:
请输入你机器人的QQ号:"
  read QQ_NUMBER
  echo "请输入你机器人的ID:"
  read BOT_ID
  echo "请输入你机器人的Token:"
  read BOT_TOKEN
  echo "请输入你机器人的AppSecret:"
  read APP_SECRET
  echo "是否群权限 (是为1, 否为0):"
  read GROUP_PERMISSION
  echo "是否频道公域 (是为0, 否为1):"
  read PUBLIC_DOMAIN

  cat <<EOF > "$CONFIG_FILE"
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
  - $QQ_NUMBER:$BOT_ID:$BOT_TOKEN:$APP_SECRET:$GROUP_PERMISSION:$PUBLIC_DOMAIN
EOF
  echo "$Y- QQBot-plugin 配置完成$O"
}

configure_icqq() {
  echo "配置 ICQQ-plugin:
请输入机器人QQ的账号:"
  read QQ_ACCOUNT
  echo "请输入机器人QQ的密码:"
  read QQ_PASSWORD

  cat <<EOF > "$CONFIG_FILE"
tips:
  - 欢迎使用 TRSS-Yunzai ICQQ Plugin ! 作者：时雨🌌星空
  - 参考：https://github.com/TimeRainStarSky/Yunzai-ICQQ-Plugin
permission: master
markdown:
  mode: false
  button: false
  callback: true
bot:
  sign_api_addr: https://hlhs-nb.cn/signed/?key=114514
token:
  - $QQ_ACCOUNT:$QQ_PASSWORD:2
EOF
  echo "正在为你检查签名"
  SIGN_API_ADDR=$(curl -sL --insecure https://hlhs-nb.cn/signed/?key=114514)
  echo "签名延迟：$SIGN_API_ADDR"
  sed -i "s|https://hlhs-nb.cn/signed/?key=114514|$SIGN_API_ADDR|g" "$CONFIG_FILE"
  echo "$Y- ICQQ-plugin 配置完成$O"
}

configure_lagrange() {
  echo "配置 Lagrange-plugin:
请输入机器人QQ账号:"
  read QQ_ACCOUNT
  echo "请输入机器人QQ密码:"
  read QQ_PASSWORD

  cat <<EOF > "$CONFIG_FILE"
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
token:
  - $QQ_ACCOUNT:$QQ_PASSWORD
EOF
  echo "$Y- Lagrange-plugin 配置完成$O"
}

choose_adapter

# 定义交互界面函数
interaction_menu() {
  echo "
请选择操作：
1) 启动 Yunzai
2) 管理插件
3) 启动 fish
4) 退出脚本
选择后按回车确认："
  read OPERATION

  case $OPERATION in
    1) cd "$DIR"; ./start.sh;;
    2) cd "$DIR/plugins"; echo "插件管理功能暂未实现";;
    3) fish;;
    4) exit 0;;
    *) echo "$R! 无效的操作$O";;
  esac
}

# 创建快捷命令
echo "alias rabbit='bash $CMDPATH/$CMD'" >> ~/.bashrc
source ~/.bashrc

# 启动交互界面
interaction_menu
