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

    # group column: the "# role=x site=y" comment netbox_ssh writes above each Host. Pick the
    # key with FZF_SSH_GROUP_BY (role, site, or none for a plain list); default role.
    # Hosts without the comment sort under "-"
    set -l by role
    set -q FZF_SSH_GROUP_BY; and set by $FZF_SSH_GROUP_BY

    # lines are group<TAB>host, sorted so a group stays together, then padded to the widest
    # group (awk, as a tab stop is too narrow for long roles). fzf shows both; the host is the
    # last word, which is what we print. Hosts have no spaces
    set -l pick (cat $files 2>/dev/null \
        | awk -v by=$by '
            by != "none" && match($0, "^[ \t]*#.*[ \t]" by "=[^ \t]+") {
                grp = substr($0, RSTART, RLENGTH)
                sub(".*" by "=", "", grp)
                next
            }
            tolower($1) == "host" {
                for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print (by == "none" ? "" : (grp == "" ? "-" : grp)) "\t" $i
                grp = ""
            }' \
        | sort -u \
        | awk -F '\t' '{ g[NR] = $1; h[NR] = $2; if (length($1) > w) w = length($1) }
            END { for (i = 1; i <= NR; i++) printf "%-" w "s  %s\n", g[i], h[i] }' \
        | fzf --height 40% --reverse --prompt 'ssh> ' \
        --preview 'ssh -G {-1} 2>/dev/null | grep -E "^(hostname|user|port|proxyjump|identityfile) "')
    string match -r '\S+$' -- $pick
end
