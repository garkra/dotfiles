#!/bin/sh
# Toggle the kitty tab bar by reloading the config with/without a
# tab_bar_style=hidden override. State is tracked per kitty instance
# (keyed off the remote-control socket name).
state="/tmp/kitty-tab-bar-hidden-${KITTY_LISTEN_ON##*/}"
if [ -e "$state" ]; then
    rm -f "$state"
    kitten @ load-config --ignore-overrides
else
    touch "$state"
    kitten @ load-config -o tab_bar_style=hidden
fi
