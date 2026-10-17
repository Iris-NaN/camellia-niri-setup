#!/bin/sh
# 耳机/键盘上的播放暂停键统一处理
#
# 目的：
#   1. 无论固件发的是 XF86AudioPlay 还是 XF86AudioPause，都做"切换"
#      （以前 XF86AudioPause 只绑了 pause，所以按一下就再也起不来）
#   2. 300ms 内重复触发只算一次。有些设备一次按键会连发两个码，
#      不去抖的话等于切换两次 = 没按
#
# 用 flock 串行化：两个进程同时起来时，后一个会等前一个写完时间戳再判断。
# 否则两个进程都读到旧时间戳，去抖会失效（实测踩过这个坑）。

STAMP="${XDG_RUNTIME_DIR:-/tmp}/media-toggle.stamp"
LOCK="${STAMP}.lock"
WINDOW_MS=300

exec 9>"$LOCK"
flock 9

now=$(date +%s%N)
if [ -f "$STAMP" ]; then
    last=$(cat "$STAMP" 2>/dev/null || echo 0)
    delta_ms=$(( (now - last) / 1000000 ))
    if [ "$delta_ms" -lt "$WINDOW_MS" ]; then
        exec 9>&-
        exit 0
    fi
fi
echo "$now" > "$STAMP"
exec 9>&-

exec playerctl play-pause
