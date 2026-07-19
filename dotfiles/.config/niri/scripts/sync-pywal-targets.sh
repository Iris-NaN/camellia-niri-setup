#!/usr/bin/env bash

set -u

palette="$HOME/.cache/wal/colors.sh"
kitty_palette="$HOME/.cache/wal/colors-kitty.conf"

[[ -r "$palette" && -r "$kitty_palette" ]] || exit 0
set +u
source "$palette"
set -u

kitty_color() {
    awk -v key="$1" '$1 == key { print $2; exit }' "$kitty_palette"
}

c0=$(kitty_color color0)
c1=$(kitty_color color1)
c2=$(kitty_color color2)
c3=$(kitty_color color3)
c4=$(kitty_color color4)
c5=$(kitty_color color5)
c6=$(kitty_color color6)
c7=$(kitty_color color7)
c8=$(kitty_color color8)

set_btop() {
    local file="$HOME/.config/btop/themes/kitty.theme"
    [[ -f "$file" ]] || return 0
    sed -i \
        -e "s|theme\[main_bg\]=.*|theme[main_bg]=\"$background\"|" \
        -e "s|theme\[main_fg\]=.*|theme[main_fg]=\"$foreground\"|" \
        -e "s|theme\[title\]=.*|theme[title]=\"$c5\"|" \
        -e "s|theme\[hi_fg\]=.*|theme[hi_fg]=\"$c4\"|" \
        -e "s|theme\[selected_bg\]=.*|theme[selected_bg]=\"$c0\"|" \
        -e "s|theme\[selected_fg\]=.*|theme[selected_fg]=\"$foreground\"|" \
        -e "s|theme\[inactive_fg\]=.*|theme[inactive_fg]=\"$c8\"|" \
        -e "s|theme\[graph_text\]=.*|theme[graph_text]=\"$c6\"|" \
        -e "s|theme\[meter_bg\]=.*|theme[meter_bg]=\"$c0\"|" \
        -e "s|theme\[proc_misc\]=.*|theme[proc_misc]=\"$c3\"|" \
        -e "s|theme\[cpu_box\]=.*|theme[cpu_box]=\"$c5\"|" \
        -e "s|theme\[mem_box\]=.*|theme[mem_box]=\"$c4\"|" \
        -e "s|theme\[net_box\]=.*|theme[net_box]=\"$c6\"|" \
        -e "s|theme\[proc_box\]=.*|theme[proc_box]=\"$c2\"|" \
        -e "s|theme\[div_line\]=.*|theme[div_line]=\"$c8\"|" \
        -e "s|theme\[temp_start\]=.*|theme[temp_start]=\"$c2\"|" \
        -e "s|theme\[temp_mid\]=.*|theme[temp_mid]=\"$c4\"|" \
        -e "s|theme\[temp_end\]=.*|theme[temp_end]=\"$c5\"|" \
        -e "s|theme\[cpu_start\]=.*|theme[cpu_start]=\"$c1\"|" \
        -e "s|theme\[cpu_mid\]=.*|theme[cpu_mid]=\"$c4\"|" \
        -e "s|theme\[cpu_end\]=.*|theme[cpu_end]=\"$c5\"|" \
        -e "s|theme\[free_start\]=.*|theme[free_start]=\"$c2\"|" \
        -e "s|theme\[free_mid\]=.*|theme[free_mid]=\"$c3\"|" \
        -e "s|theme\[free_end\]=.*|theme[free_end]=\"$c4\"|" \
        -e "s|theme\[cached_start\]=.*|theme[cached_start]=\"$c3\"|" \
        -e "s|theme\[cached_mid\]=.*|theme[cached_mid]=\"$c4\"|" \
        -e "s|theme\[cached_end\]=.*|theme[cached_end]=\"$c5\"|" \
        -e "s|theme\[available_start\]=.*|theme[available_start]=\"$c6\"|" \
        -e "s|theme\[available_mid\]=.*|theme[available_mid]=\"$c7\"|" \
        -e "s|theme\[available_end\]=.*|theme[available_end]=\"$foreground\"|" \
        -e "s|theme\[used_start\]=.*|theme[used_start]=\"$c5\"|" \
        -e "s|theme\[used_mid\]=.*|theme[used_mid]=\"$c4\"|" \
        -e "s|theme\[used_end\]=.*|theme[used_end]=\"$c1\"|" \
        -e "s|theme\[download_start\]=.*|theme[download_start]=\"$c2\"|" \
        -e "s|theme\[download_mid\]=.*|theme[download_mid]=\"$c6\"|" \
        -e "s|theme\[download_end\]=.*|theme[download_end]=\"$foreground\"|" \
        -e "s|theme\[upload_start\]=.*|theme[upload_start]=\"$c1\"|" \
        -e "s|theme\[upload_mid\]=.*|theme[upload_mid]=\"$c3\"|" \
        -e "s|theme\[upload_end\]=.*|theme[upload_end]=\"$c5\"|" \
        "$file"
}

set_swaylock() {
    local file="$HOME/.config/swaylock/config"
    [[ -f "$file" ]] || return 0
    sed -i \
        -e "s/^key-hl-color=.*/key-hl-color=${c5#\#}cc/" \
        -e "s/^inside-color=.*/inside-color=${background#\#}b3/" \
        -e "s/^ring-color=.*/ring-color=${foreground#\#}ff/" \
        -e "s/^ring-clear-color=.*/ring-clear-color=${c5#\#}ff/" \
        -e "s/^ring-ver-color=.*/ring-ver-color=${c2#\#}ff/" \
        -e "s/^ring-wrong-color=.*/ring-wrong-color=${c1#\#}ff/" \
        -e "s/^text-color=.*/text-color=${foreground#\#}ff/" \
        -e "s/^text-clear-color=.*/text-clear-color=${foreground#\#}ff/" \
        -e "s/^text-ver-color=.*/text-ver-color=${foreground#\#}ff/" \
        -e "s/^text-wrong-color=.*/text-wrong-color=${foreground#\#}ff/" \
        "$file"
}

set_neovim() {
    local file="$HOME/.config/nvim/colors/kitty.lua"
    [[ -f "$file" ]] || return 0
    sed -i \
        -e "s/bg = \"#[0-9A-Fa-f]*\"/bg = \"$background\"/" \
        -e "s/bg_dark = \"#[0-9A-Fa-f]*\"/bg_dark = \"$c0\"/" \
        -e "s/fg = \"#[0-9A-Fa-f]*\"/fg = \"$foreground\"/" \
        -e "s/muted = \"#[0-9A-Fa-f]*\"/muted = \"$c8\"/" \
        -e "s/red = \"#[0-9A-Fa-f]*\"/red = \"$c1\"/" \
        -e "s/green = \"#[0-9A-Fa-f]*\"/green = \"$c2\"/" \
        -e "s/yellow = \"#[0-9A-Fa-f]*\"/yellow = \"$c3\"/" \
        -e "s/blue = \"#[0-9A-Fa-f]*\"/blue = \"$c4\"/" \
        -e "s/magenta = \"#[0-9A-Fa-f]*\"/magenta = \"$c5\"/" \
        -e "s/cyan = \"#[0-9A-Fa-f]*\"/cyan = \"$c6\"/" \
        "$file"
}

set_zed() {
    local file="$HOME/.config/zed/themes/kitty-green.json"
    [[ -f "$file" ]] || return 0
    sed -i \
        -e "0,/\"background\":/s|\"background\": \"#[0-9A-Fa-f]*\"|\"background\": \"$background\"|" \
        -e "s|\"text\": \"#[0-9A-Fa-f]*\"|\"text\": \"$foreground\"|" \
        -e "s|\"text.muted\": \"#[0-9A-Fa-f]*\"|\"text.muted\": \"$c8\"|" \
        -e "s|\"border.focused\": \"#[0-9A-Fa-f]*\"|\"border.focused\": \"$c5\"|" \
        -e "s|\"editor.foreground\": \"#[0-9A-Fa-f]*\"|\"editor.foreground\": \"$foreground\"|" \
        "$file"
}

set_btop
set_swaylock
set_neovim
set_zed
