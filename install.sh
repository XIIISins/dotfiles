#!/bin/sh
# Symlink manager: each directory in ./config becomes $XDG_CONFIG_HOME/<name>.
#
#   ./install.sh [-n] [--server] [link|unlink|status|hooks] [package ...]
#
#   link    (default) symlink packages, backing up whatever is already there
#   unlink  replace the symlink with a real copy of the repo files
#   status  show what is linked
#   hooks   re-run the post-link steps of linked packages (they only run on a fresh link)
#   -n      dry run, change nothing
#   --server  check out the `server` branch (bash, tmux, nvim, git only) and run its
#           install.sh instead; for a fresh clone on a server, not for a checkout that is
#           already linked into ~/.config

set -eu

repo=$(cd "$(dirname "$0")" && pwd)
dest=${XDG_CONFIG_HOME:-$HOME/.config}
os=$(uname -s)
dry=0
server=0

packages="fish tmux ghostty hammerspoon karabiner nvim lazygit git palette claude-mods fastfetch zen"

# packages that only make sense on one OS (uname -s); empty means everywhere
only_on() {
    case $1 in
        hammerspoon | karabiner | zen) echo Darwin ;;
        *) echo "" ;;
    esac
}

# machine-local paths (gitignored) carried over from the old directory on first link
local_paths() {
    case $1 in
        fish) echo "fish_variables config-local.fish" ;;
        tmux) echo "plugins" ;;
        karabiner) echo "automatic_backups" ;;
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

# Zen keeps its prefs in a per-machine profile, not ~/.config: link the tracked
# files into the install's default profile (named in installs.ini)
zen_profile_links() {
    zen_dir="$HOME/Library/Application Support/zen"
    rel=$(sed -n 's/^Default=//p' "$zen_dir/installs.ini" 2>/dev/null | head -n 1)
    if [ -z "$rel" ] || [ ! -d "$zen_dir/$rel" ]; then
        echo "zen: no profile found in $zen_dir; start Zen once, then run: ./install.sh hooks zen"
        return 0
    fi
    for f in user.js zen-keyboard-shortcuts.json; do
        t=$zen_dir/$rel/$f
        if is_linked "$dest/zen/$f" "$t"; then
            continue
        fi
        if [ -e "$t" ] || [ -L "$t" ]; then
            run mv "$t" "$t.bak-$(date +%Y%m%d-%H%M%S)"
        fi
        echo "zen: linking $t -> $dest/zen/$f"
        run ln -s "$dest/zen/$f" "$t"
    done
    echo "zen: restart Zen to pick up the changes"
}

# things that need doing once the link exists
hook() {
    if [ -n "${DOTFILES_SKIP_HOOKS:-}" ]; then
        return 0
    fi
    case $1 in
        hammerspoon)
            # Hammerspoon reads ~/.hammerspoon unless told otherwise
            soft defaults write org.hammerspoon.Hammerspoon MJConfigFile "$dest/hammerspoon/init.lua"
            ;;
        zen)
            zen_profile_links
            ;;
        claude-mods)
            # plugins live in ~/.claude, not ~/.config: register the linked
            # directory as a marketplace and install from it
            if command -v claude >/dev/null 2>&1; then
                soft claude plugin marketplace add "$dest/claude-mods"
                soft claude plugin install usage-band@xiiisins-mods
                soft claude plugin install tokyonight-moon@xiiisins-mods
                soft claude plugin install todo@xiiisins-mods
            else
                echo "claude-mods: claude not found; later run: claude plugin marketplace add $dest/claude-mods"
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

# --server: this checkout is the full desktop setup, the servers get the `server` branch. Switch to
# it and hand over to its install.sh, so one command works on a fresh clone of main.
switch_to_server() {
    if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
        echo "--server: $repo is not a git checkout" >&2
        exit 1
    fi
    if [ "$(git -C "$repo" symbolic-ref -q --short HEAD)" = server ]; then
        return 0 # already on it: this is its own install.sh
    fi
    # switching branches rewrites the files a linked ~/.config points at
    for pkg in $packages; do
        if is_linked "$repo/config/$pkg" "$dest/$pkg"; then
            echo "--server: $dest/$pkg is linked from this checkout; switching branches would change" >&2
            echo "          the live config. Use a separate clone for the server variant." >&2
            exit 1
        fi
    done
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        echo "--server: uncommitted changes in $repo; commit or stash them first" >&2
        exit 1
    fi
    run git -C "$repo" fetch origin server
    if git -C "$repo" show-ref --verify -q refs/heads/server; then
        run git -C "$repo" checkout server
        soft git -C "$repo" merge --ff-only origin/server
    else
        run git -C "$repo" checkout --track origin/server
    fi
    if [ "$dry" = 1 ]; then
        echo "    would: run the server branch's install.sh $cmd $*"
        exit 0
    fi
    # the server branch has its own install.sh (with its own package list): hand over to it
    exec "$repo/install.sh" "$cmd" "$@"
}

cmd=link
while [ $# -gt 0 ]; do
    case $1 in
        -n | --dry-run) dry=1 ;;
        --server) server=1 ;;
        link | unlink | status | hooks) cmd=$1 ;;
        -h | --help)
            sed -n '2,13p' "$0"
            exit 0
            ;;
        *) break ;;
    esac
    shift
done

if [ "$server" = 1 ]; then
    switch_to_server "$@"
fi

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
