alias ls "ls -p -G"

if type -q cursor-agent
    alias ca cursor-agent
end

# Homebrew
test -x /opt/homebrew/bin/brew; and /opt/homebrew/bin/brew shellenv | source

# Node.js (nvm; the Homebrew node@22 PATH that .zshrc sets would fight it)
set -g nvm_default_version lts

# Ruby (same rbenv setup as .zshrc, otherwise fish gets the system ruby)
if type -q rbenv
    rbenv init - fish | source
end
