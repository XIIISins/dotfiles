set fish_greeting ""

# set -gx TERM xterm-256color

# prompt
set -g fish_prompt_pwd_dir_length 1

# aliases
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"

if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end

if type -q nvim
    alias vi nvim
    alias vim nvim
end

# abbreviations expand as you type, so history and pasted commands show the real command.
# Staging stays by file name (no `git add -A`), see CLAUDE.md.
abbr -a g git
abbr -a gst 'git status'
abbr -a ga 'git add'
abbr -a gc 'git commit'
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a gl 'git lg'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gf 'git fetch'
abbr -a gsw 'git switch'
abbr -a gsc 'git switch -c'
# sudo !! reruns the last command
abbr -a '!!' --position anywhere --function last_history_item

type -q systemctl; and abbr -a sc systemctl; and abbr -a jc journalctl
type -q kubectl; and abbr -a k kubectl
type -q docker; and abbr -a dk docker

# fzf pickers (functions/fzf_*.fish); the abbreviations are the short way to call them
if type -q fzf
    abbr -a fb fzf_git_branch
    abbr -a fw fzf_git_worktree
    abbr -a fsh fzf_ssh
end

# zoxide (z, zi)
if type -q zoxide
    zoxide init fish | source
end

# Fzf
if type -q bat
    set -g fzf_preview_file_cmd "bat --style=numbers --color=always --line-range :500"
end

set -gx EDITOR nvim

# PATH (fish_add_path dedupes; later calls take precedence)
fish_add_path -g /usr/local/bin ~/.local/bin ~/bin

# Go
set -gx GOPATH $HOME/go
fish_add_path -g $GOPATH/bin

set -l config_dir (dirname (status --current-filename))

switch (uname)
    case Darwin
        source $config_dir/config-osx.fish
    case Linux
        source $config_dir/config-linux.fish
    case '*'
        source $config_dir/config-windows.fish
end

# machine-local settings live outside the repo; config-local.fish is the old place, still read
# (first, so the new file wins) until every machine has moved
set -l local_dir (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/local
for f in $config_dir/config-local.fish $local_dir/fish/config.fish
    test -f $f; and source $f
end

# New machine: install fisher and the plugins listed in fish_plugins, then apply the
# tracked tide settings (fisher pinned to the 4.4.8 commit). Runs in a non-interactive child so tide skips its first-run prompts.
if status is-interactive; and not functions -q fisher; and test -f $config_dir/fish_plugins; and type -q curl
    echo "fish: installing fisher plugins..."
    fish -c '
        curl -sL --connect-timeout 3 --max-time 20 https://raw.githubusercontent.com/jorgebucaran/fisher/a04308be92daa6cfecdbb0ca58b1e8508664cff2/functions/fisher.fish | source
        and fisher update
        and source $argv[1]/tide-settings.fish
    ' $config_dir
    and exec fish
end

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish
