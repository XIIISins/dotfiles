if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end

if type -q nvim
    alias vi nvim
    alias vim nvim
end

if type -q cursor-agent
    alias ca cursor-agent
end

# Fzf
if type -q bat
    set -g fzf_preview_file_cmd "bat --style=numbers --color=always --line-range :500"
end

# Homebrew
test -x /opt/homebrew/bin/brew; and /opt/homebrew/bin/brew shellenv | source

# Node.js (nvm; the Homebrew node@22 PATH that .zshrc sets would fight it)
set -g nvm_default_version lts

# Ruby (same rbenv setup as .zshrc, otherwise fish gets the system ruby)
if type -q rbenv
    rbenv init - fish | source
end
