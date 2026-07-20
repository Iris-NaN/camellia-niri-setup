#!/usr/bin/env bash

set -eu

cat <<'EOF' | fuzzel --dmenu --prompt='搜索快捷键  ' --lines=20 --width=68 >/dev/null
── 应用与系统 ─────────────────────────────────────────
Mod + T                      打开终端
Mod + D                      打开应用启动器
Mod + Shift + D              选择 Emoji 并复制
Mod + C                      打开文件管理器
Mod + E                      打开浏览器
Mod + L                      锁定屏幕
Mod + X                      打开电源菜单
── 窗口与焦点 ─────────────────────────────────────────
Mod + Q                      关闭窗口
Mod + V                      切换浮动窗口
Mod + F                      最大化当前列
Mod + Shift + F              当前窗口全屏
Mod + ← / →                  左右切换焦点，可跨屏
Mod + ↑ / ↓                  上下切换焦点，可跨屏
Mod + Ctrl + ← / →           左右移动当前列，可跨屏
Mod + Ctrl + ↑ / ↓           上下移动当前窗口
Mod + Home / End             焦点移到首列 / 末列
Mod + Ctrl + Home / End      当前列移到最前 / 最后
Mod + Ctrl + Shift + ↑ / ↓   当前列移到上方 / 下方屏幕
── 工作区 ─────────────────────────────────────────────
Mod + - / PageUp             上一个工作区
Mod + = / PageDown           下一个工作区
Mod + Ctrl + - / PageUp      当前列移到上一个工作区
Mod + Ctrl + = / PageDown    当前列移到下一个工作区
Mod + 数字键                 切换到指定工作区
Mod + Ctrl + 数字键          当前列移到指定工作区
Mod + A                      切换总览
── 布局与尺寸 ─────────────────────────────────────────
Mod + Shift + H / L          增大 / 缩小列宽
Mod + Shift + J / K          增加 / 降低窗口高度
Mod + [ / ]                  向左 / 右吸收或移出窗口
Mod + , / .                  将窗口并入 / 移出当前列
── 工具与媒体 ─────────────────────────────────────────
Mod + W                      选择壁纸
Mod + Shift + W              随机壁纸
Mod + Alt + C                剪贴板历史
Mod + Alt + B                重新加载 Waybar
Mod + Alt + M                切换蓝牙音频模式
Print                        截取整个屏幕
Shift + Print                选择区域截图
Ctrl + Print                 截取当前窗口
亮度键                       调整屏幕亮度
音量 / 静音 / 媒体键         控制音频与播放
Mod + Shift + /              打开本速查表
EOF
