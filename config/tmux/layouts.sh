#!/bin/sh
# named pane layouts: pick one in an fzf popup and the window is reshaped to it
# usage: layouts.sh pick WINDOW          fzf popup (run inside display-popup)
#        layouts.sh apply WINDOW NAME    reshape WINDOW to the saved layout NAME
#        layouts.sh save WINDOW NAME     store WINDOW's current layout as NAME
#        layouts.sh delete NAME
#        layouts.sh list [WINDOW]        name<TAB>label lines, as fzf shows them
# layouts live in ./layouts as name<TAB>pane count<TAB>layout, where layout is
# tmux's own #{window_layout}. tmux 3.8 prints it as JSON, which older tmux
# cannot parse; it scales to the window size, so one layout fits any window

self=$0
dir=$(dirname "$0")
file=${LAYOUTS_FILE:-$dir/layouts}

# the message goes through run-shell's sh, so close and reopen the quote around any '
say() {
    msg=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
    tmux run-shell -b "sleep 0.3; '$dir/notify.sh' '$msg'"
}

# NAME's line from the file, or nothing
lookup() { awk -F'\t' -v n="$1" '$1 == n' "$file" 2>/dev/null; }

list() {
    have=
    [ -n "$1" ] && have=$(tmux display -p -t "$1" '#{window_panes}')
    awk -F'\t' -v have="$have" '
        NF < 3 { next }
        {
            note = ""
            if (have != "" && $2 > have) note = "  +" ($2 - have) " new"
            if (have != "" && $2 < have) note = "  " (have - $2) " moved to a new window"
            printf "%s\t%-18s %s pane%s%s\n", $1, $1, $2, ($2 == 1 ? "" : "s"), note
        }' "$file" 2>/dev/null
}

apply() {
    win=$1 name=$2
    line=$(lookup "$name")
    [ -n "$line" ] || { say "No layout $name"; return 1; }
    want=$(printf '%s' "$line" | cut -f2)
    layout=$(printf '%s' "$line" | cut -f3-)
    have=$(tmux display -p -t "$win" '#{window_panes}')

    # fewer panes than the layout: open the missing ones in the active pane's directory,
    # re-tiling in between so the next split always has room
    if [ "$have" -lt "$want" ]; then
        cwd=$(tmux display -p -t "$win" '#{pane_current_path}')
        while [ "$have" -lt "$want" ]; do
            tmux split-window -d -t "$win" -c "$cwd" && tmux select-layout -t "$win" tiled ||
                { say "No room for $want panes"; return 1; }
            have=$((have + 1))
        done
    fi

    # more panes than the layout: park the surplus (the last ones) in one new window
    # instead of killing them
    if [ "$have" -gt "$want" ]; then
        extra=$(tmux list-panes -t "$win" -F '#{pane_id}' | tail -n +$((want + 1)))
        new=
        for p in $extra; do
            if [ -z "$new" ]; then
                new=$(tmux break-pane -d -P -F '#{window_id}' -s "$p")
            else
                tmux join-pane -d -s "$p" -t "$new"
            fi
        done
    fi

    if err=$(tmux select-layout -t "$win" "$layout" 2>&1); then
        say "Layout $name"
    else
        say "Layout $name: $err"
    fi
}

save() {
    win=$1 name=$2
    case $name in
    '' | *"$(printf '\t')"*) say "Bad layout name"; return 1 ;;
    esac
    n=$(tmux display -p -t "$win" '#{window_panes}')
    layout=$(tmux display -p -t "$win" '#{window_layout}')
    tmp=$(mktemp)
    # replace an existing entry in place, otherwise append
    awk -F'\t' -v OFS='\t' -v n="$name" -v c="$n" -v l="$layout" '
        $1 == n { print n, c, l; done = 1; next }
        { print }
        END { if (!done) print n, c, l }' "$file" >"$tmp" 2>/dev/null || printf '%s\t%s\t%s\n' "$name" "$n" "$layout" >"$tmp"
    cat "$tmp" >"$file" && rm -f "$tmp"
    say "Saved layout $name"
}

delete() {
    tmp=$(mktemp)
    awk -F'\t' -v n="$1" '$1 != n' "$file" >"$tmp" && cat "$tmp" >"$file"
    rm -f "$tmp"
}

pick() {
    win=$1
    # TN_* colours as fzf flags come from theme.conf
    opts=$(tmux show -gqv @layouts-fzf-options)
    choice=$(list "$win" | eval fzf "$opts" --delimiter "'\t'" --with-nth 2 \
        --header "'enter apply   ctrl-x delete'" \
        --bind "'ctrl-x:execute-silent($self delete {1})+reload($self list $win)'" | cut -f1)
    [ -n "$choice" ] && apply "$win" "$choice"
}

cmd=$1
shift
case $cmd in
pick | apply | save | delete | list) "$cmd" "$@" ;;
*) echo "usage: $0 pick|apply|save|delete|list ..." >&2; exit 2 ;;
esac
