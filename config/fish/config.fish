set fish_greeting ""

# set -gx TERM xterm-256color

# prompt
set -g fish_prompt_pwd_dir_length 1

# aliases
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git

if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end

if type -q nvim
    alias vi nvim
    alias vim nvim
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

if test -f $config_dir/config-local.fish
    source $config_dir/config-local.fish
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
