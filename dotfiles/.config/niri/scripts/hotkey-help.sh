#!/usr/bin/env bash

set -eu

cat <<'EOF' | fuzzel --dmenu --prompt='快捷键  ' --lines=22 --width=58 >/dev/null
Mod + T                  打开终端
Mod + D                  打开应用启动器
Mod + C                  打开文件管理器
Mod + E                  打开浏览器
Mod + L                  锁定屏幕
Mod + Q                  关闭窗口
Mod + X                  打开电源菜单
Mod + V                  切换浮动窗口
Mod + F                  最大化当前列
Mod + Shift + F          当前窗口全屏
Mod + ← / →              左右切换焦点，可跨屏
Mod + ↑ / ↓              上下切换焦点，可跨屏
Mod + Ctrl + ← / →       左右移动当前列，可跨屏
Mod + -                  上一个工作区
Mod + =                  下一个工作区
Mod + Ctrl + -           当前列移到上一个工作区
Mod + Ctrl + =           当前列移到下一个工作区
Mod + 数字键             切换到指定工作区
Mod + Ctrl + 数字键      当前列移到指定工作区
Mod + A                  切换总览
Print                    截取整个屏幕
Mod + Shift + /          打开本速查表
EOF
