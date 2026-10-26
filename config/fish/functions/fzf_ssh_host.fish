function fzf_ssh_host
    # pick a host and print it; shared by fzf_ssh and fzf_ssh_widget (ctrl+s).
    # Hosts come from ~/.ssh/config and the files it Includes; wildcard patterns are not hosts

    # follow Include recursively, as ssh does: relative paths are under ~/.ssh, and ~ and
    # globs are allowed. cat, not `<`: fish warns on a missing file despite 2>/dev/null
    set -l files ~/.ssh/config
    set -l i 1
    while set -q files[$i]
        for pattern in (cat $files[$i] 2>/dev/null | string match -r -i -g '^\s*include[\s=]+(.+)' | string split -n ' ')
            set pattern (string replace -r '^~' -- $HOME $pattern)
            string match -q '/*' -- $pattern; or set pattern ~/.ssh/$pattern
            # sh expands the glob; the -f test also drops a pattern that matched nothing
            for f in (sh -c 'for f in $1; do [ -f "$f" ] && echo "$f"; done' _ $pattern)
                # the contains check also stops an Include cycle
                contains -- $f $files; or set -a files $f
            end
        end
        set i (math $i + 1)
    end

    cat $files 2>/dev/null \
        | awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i }' \
        | sort -u \
        | fzf --height 40% --reverse --prompt 'ssh> ' \
        --preview 'ssh -G {} | grep -E "^(hostname|user|port|proxyjump|identityfile) "'
end
