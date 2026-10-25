function fzf_ssh
    # hosts come from ~/.ssh/config and ~/.ssh/config.d/*; wildcard patterns are not hosts.
    # Extra arguments go to ssh, e.g. `fzf_ssh -t tmux attach`
    set -l files ~/.ssh/config ~/.ssh/config.d/*
    set -l host (cat $files 2>/dev/null \
        | awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i }' \
        | sort -u \
        | fzf --height 40% --reverse --prompt 'ssh> ' \
            --preview 'ssh -G {} | grep -E "^(hostname|user|port|proxyjump|identityfile) "')
    test -n "$host"; or return
    ssh $host $argv
end
