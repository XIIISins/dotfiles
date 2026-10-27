#!/bin/sh
# Teams (teams-cli, `teams` on its default profile) in tmux; utility.conf wires it up
# usage: teams.sh popup   body of the prefix t popup: attach the `teams` session,
#                         started on first use and left running when the popup closes
#        teams.sh watch   background poller: counts chats with a message newer than
#                         the last time the popup was open into @teams_unread (the
#                         status line shows it) and pops a notify.sh notch when one
#                         arrives. teams-cli never marks chats read, so having the
#                         popup open counts as having seen them.

interval=30
dir=$(dirname "$0")

seen() {
    tmux set -g @teams_seen "$(date +%s)" \; set -g @teams_unread ''
}

# "<count> <newest epoch>" of chats unread in Teams whose last message is newer than $1;
# the read rule matches teams-cli's own unread dot (render.rs is_unread)
unread() {
    jq -r --argjson seen "$1" '
        def t: sub("\\.[0-9]+"; "") | fromdateiso8601;  # drop the milliseconds jq cannot parse
        [.items[]
         | .lastMessagePreview as $m
         | select(($m.messageType // "message") == "message")
         | select($m.createdDateTime and .viewpoint.lastMessageReadDateTime)
         | ($m.createdDateTime | t) as $sent
         | select($sent > (.viewpoint.lastMessageReadDateTime | t) and $sent > $seen)
         | $sent]
        | "\(length) \(max // 0)"'
}

case ${1:-} in
popup)
    seen
    # the popup inherits TMUX, and tmux refuses to attach from inside tmux
    env -u TMUX tmux new-session -A -s teams teams \; set -t teams status off
    seen
    ;;
watch)
    # one watcher per server: a config reload starts another, which leaves again
    pid=$(tmux show -gv @teams_watch_pid 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        exit 0
    fi
    tmux set -g @teams_watch_pid $$ || exit 0
    notified=$(date +%s)
    # ends with the server, or when another watcher has taken over
    while [ "$(tmux show -gv @teams_watch_pid 2>/dev/null)" = $$ ]; do
        if ! tmux has-session -t '=teams' 2>/dev/null; then
            tmux set -g @teams_unread ''
        elif [ -n "$(tmux list-clients -t '=teams' 2>/dev/null)" ]; then
            seen # popup open
        elif json=$(teams chats list --limit 50 -o json --quiet 2>/dev/null); then
            since=$(tmux show -gv @teams_seen 2>/dev/null)
            # shellcheck disable=SC2046 # split "<count> <newest>" into $1 $2
            set -- $(printf '%s' "$json" | unread "${since:-0}")
            count=${1:-0} newest=${2:-0}
            if [ "$count" -gt 0 ]; then
                tmux set -g @teams_unread "$count"
            else
                tmux set -g @teams_unread ''
            fi
            if [ "$newest" -gt "$notified" ]; then
                notified=$newest
                "$dir/notify.sh" "Teams: $count unread" 3
            fi
        fi
        sleep "$interval"
    done
    ;;
*)
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 1
    ;;
esac
