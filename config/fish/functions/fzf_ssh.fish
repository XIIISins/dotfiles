function fzf_ssh
    # pick a host (fzf_ssh_host) and connect.
    # Extra arguments go to ssh, e.g. `fzf_ssh -t tmux attach`
    set -l host (fzf_ssh_host)
    test -n "$host"; or return
    ssh $host $argv
end
