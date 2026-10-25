#!/bin/sh
# Symlink manager: each directory in ./config becomes $XDG_CONFIG_HOME/<name>.
#
#   ./install.sh [-n] [link|unlink|status|hooks] [package ...]
#
#   link    (default) symlink packages, backing up whatever is already there
#   unlink  replace the symlink with a real copy of the repo files
#   status  show what is linked
#   hooks   re-run the post-link steps of linked packages (they only run on a fresh link)
#   -n      dry run, change nothing

set -eu

repo=$(cd "$(dirname "$0")" && pwd)
dest=${XDG_CONFIG_HOME:-$HOME/.config}
os=$(uname -s)
dry=0

packages="shell tmux nvim git palette"

# packages that only make sense on one OS (uname -s); empty means everywhere
only_on() {
    echo ""
}

# machine-local paths (gitignored) carried over from the old directory on first link
local_paths() {
    case $1 in
        git) echo "config.local" ;;
    esac
}

run() {
    if [ "$dry" = 1 ]; then
        printf '    would: %s\n' "$*"
    else
        "$@"
    fi
}

# like run, but a failing hook must not abort the remaining packages
soft() {
    run "$@" || echo "    failed (continuing): $*" >&2
}

supported() {
    want=$(only_on "$1")
    [ -z "$want" ] || [ "$want" = "$os" ]
}

is_linked() {
    [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]
}

# things that need doing once the link exists
hook() {
    if [ -n "${DOTFILES_SKIP_HOOKS:-}" ]; then
        return 0
    fi
    case $1 in
        shell)
            # bash reads ~/.bashrc, not ~/.config: add one line that sources ours
            rc=$HOME/.bashrc
            line='. "${XDG_CONFIG_HOME:-$HOME/.config}/shell/bashrc"'
            if [ -f "$rc" ] && grep -qF "$line" "$rc"; then
                echo "shell: $rc already sources it"
            else
                echo "shell: adding the source line to $rc"
                run sh -c 'printf "%s\n" "$1" >> "$2"' sh "$line" "$rc"
            fi
            ;;
    esac
}

link_pkg() {
    pkg=$1
    src=$repo/config/$pkg
    tgt=$dest/$pkg

    if [ ! -d "$src" ]; then
        echo "$pkg: missing $src"
        return 1
    fi
    if ! supported "$pkg"; then
        echo "$pkg: skipped (only on $(only_on "$pkg"))"
        return 0
    fi
    if is_linked "$src" "$tgt"; then
        echo "$pkg: already linked"
        return 0
    fi

    backup=
    if [ -e "$tgt" ] || [ -L "$tgt" ]; then
        backup=$tgt.bak-$(date +%Y%m%d-%H%M%S)
        echo "$pkg: backing up $tgt -> $backup"
        run mv "$tgt" "$backup"
    fi

    echo "$pkg: linking $tgt -> $src"
    run mkdir -p "$dest"
    run ln -s "$src" "$tgt"

    # carry machine-local files over so nothing breaks on the first link
    if [ -n "$backup" ]; then
        old=$backup
        if [ "$dry" = 1 ]; then
            old=$tgt
        fi
        # symlinks into other repos are machine-local too
        links=$(cd "$old" && find . -type l -not -path './plugins/*' | sed 's|^\./||')
        for p in $(local_paths "$pkg") $links; do
            if [ -e "$src/$p" ] || [ -L "$src/$p" ]; then
                continue
            fi
            if [ -e "$old/$p" ] || [ -L "$old/$p" ]; then
                echo "$pkg: keeping local $p"
                run mkdir -p "$(dirname "$src/$p")"
                run cp -PR "$old/$p" "$src/$p"
            fi
        done
    fi

    hook "$pkg"
}

unlink_pkg() {
    pkg=$1
    src=$repo/config/$pkg
    tgt=$dest/$pkg

    if ! is_linked "$src" "$tgt"; then
        echo "$pkg: not linked"
        return 0
    fi
    echo "$pkg: replacing the symlink with a copy of $src"
    run rm "$tgt"
    run cp -PR "$src" "$tgt"
}

hooks_pkg() {
    pkg=$1
    if ! supported "$pkg"; then
        echo "$pkg: skipped (only on $(only_on "$pkg"))"
    elif is_linked "$repo/config/$pkg" "$dest/$pkg"; then
        echo "$pkg: running hooks"
        hook "$pkg"
    else
        echo "$pkg: not linked"
    fi
}

status_pkg() {
    pkg=$1
    src=$repo/config/$pkg
    tgt=$dest/$pkg

    if ! supported "$pkg"; then
        echo "$pkg: n/a on $os"
    elif is_linked "$src" "$tgt"; then
        echo "$pkg: linked"
    elif [ -e "$tgt" ] || [ -L "$tgt" ]; then
        echo "$pkg: not linked ($tgt exists)"
    else
        echo "$pkg: not linked"
    fi
}

cmd='link'
while [ $# -gt 0 ]; do
    case $1 in
        -n | --dry-run) dry=1 ;;
        link | unlink | status | hooks) cmd=$1 ;;
        -h | --help)
            sed -n '2,10p' "$0"
            exit 0
            ;;
        *) break ;;
    esac
    shift
done

if [ $# -gt 0 ]; then
    selected=$*
else
    selected=$packages
fi

for pkg in $selected; do
    case " $packages " in
        *" $pkg "*) ;;
        *)
            echo "unknown package: $pkg (known: $packages)" >&2
            exit 1
            ;;
    esac
done

for pkg in $selected; do
    "${cmd}_pkg" "$pkg"
done

# the repo's own pre-commit hook (.githooks/); core.hooksPath is shared by all worktrees
if [ -d "$repo/.githooks" ] && { [ "$cmd" = link ] || [ "$cmd" = hooks ]; }; then
    soft git -C "$repo" config core.hooksPath .githooks
fi
