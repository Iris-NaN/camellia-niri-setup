#!/bin/sh
# 键盘控制鼠标指针
# 用 ydotool 在内核 uinput 层模拟真实鼠标事件，因此对任何 Wayland app 都有效。
#
# 用法:
#   pointer-key.sh toggle                      开关指针键模式
#   pointer-key.sh move <dx> <dy>              相对移动（负数表示左/上）
#   pointer-key.sh click <0xC0|0xC1|0xC2>      左键/右键/中键
#   pointer-key.sh scroll <up|down>            滚动一屏

STATE="${XDG_RUNTIME_DIR:-/tmp}/niri-pointer-mode"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-${XDG_RUNTIME_DIR:-/tmp}/.ydotool_socket}"

case "$1" in
toggle)
    if [ -e "$STATE" ]; then
        rm -f "$STATE"
        notify-send -u low -t 800 -a "指针键" "指针键 · 关闭" "方向键恢复原样"
    else
        : > "$STATE"
        notify-send -u low -t 1500 -a "指针键" "指针键 · 开启" "H/J/K/L 移动 · U 左键 · I 右键 · O 中键"
    fi
    ;;
move)
    [ -e "$STATE" ] || exit 0
    exec ydotool mousemove -- "$2" "$3"
    ;;
click)
    [ -e "$STATE" ] || exit 0
    exec ydotool click "$2"
    ;;
scroll)
    [ -e "$STATE" ] || exit 0
    case "$2" in
    up)   exec ydotool key 104:1 104:0 ;;   # PageUp
    down) exec ydotool key 109:1 109:0 ;;   # PageDown
    esac
    ;;
*)
    echo "用法: $0 toggle|move dx dy|click 0xC0|scroll up|down" >&2
    exit 2
    ;;
esac
