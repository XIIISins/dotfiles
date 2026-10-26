function fzf_ssh_host
    # pick a host and print it; shared by fzf_ssh and fzf_ssh_widget (ctrl+s).
    # Hosts come from ~/.ssh/config and ~/.ssh/config.d/*; wildcard patterns are not hosts
    set -l files ~/.ssh/config ~/.ssh/config.d/*
    cat $files 2>/dev/null \
        | awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i }' \
        | sort -u \
        | fzf --height 40% --reverse --prompt 'ssh> ' \
        --preview 'ssh -G {} | grep -E "^(hostname|user|port|proxyjump|identityfile) "'
end
