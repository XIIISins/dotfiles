#!/bin/sh
# floating "notch" notification near the top of the client
# usage: notify.sh "message" [seconds]
#        notify.sh --confirm "question" "done message" tmux-command...
# needs tmux 3.3+ for popup styling, otherwise falls back to the status line

self=$0

# pill MESSAGE: print the rounded black pill (caps blend into the window bg
# #222436; popups paint unset backgrounds grey, so every bg is set explicitly)
pill() {
    printf '\033[?25l\033[0m\033[48;2;34;36;54m\033[38;2;0;0;0m\356\202\266\033[48;2;0;0;0m \033[38;2;200;211;245m%s \033[48;2;34;36;54m\033[38;2;0;0;0m\356\202\264\033[0m' "$1"
}

# width in cells: left cap + space + message + space + right cap
cells() { echo $(($(printf '%s' "$1" | wc -m | tr -d ' ') + 4)); }

case $1 in
--ask)
    # runs inside the popup: show the question, act on y, anything else cancels
    pill "$NOTIFY_Q (y/n)"
    stty -icanon -echo min 1 2>/dev/null
    key=$(dd bs=1 count=1 2>/dev/null)
    case $key in
    y | Y)
        eval "tmux $NOTIFY_CMD"
        tmux run-shell -b "sleep 0.3; '$self' '$NOTIFY_DONE'"
        ;;
    esac
    ;;
--confirm)
    q=$2 done=$3
    shift 3
    tmux display-popup -E -B -s 'bg=#222436' -x C -y 1 -w "$(cells "$q (y/n)")" -h 1 \
        -e "NOTIFY_Q=$q" -e "NOTIFY_DONE=$done" -e "NOTIFY_CMD=$*" "'$self' --ask" 2>/dev/null ||
        tmux confirm-before -p "$q (y/n)" "$*"
    ;;
*)
    msg=$1
    secs=${2:-1.2}
    tmux display-popup -E -B -s 'bg=#222436' -x C -y 1 -w "$(cells "$msg")" -h 1 \
        "printf '%s' '$(pill "$msg")'; sleep $secs" 2>/dev/null ||
        tmux display-message "$msg"
    ;;
esac
