function fzf_systemd
    # pick a service, then act on it: status (default), logs (follow), restart, stop
    # or edit. Add --user (anywhere) for the user manager: `fzf_systemd logs --user`
    set -l scope --system
    if set -l i (contains -i -- --user $argv)
        set scope --user
        set -e argv[$i]
    end

    set -l action status
    set -q argv[1]; and set action $argv[1]
    if set -q argv[2]; or not contains -- $action status logs restart stop edit
        echo "usage: fzf_systemd [status|logs|restart|stop|edit] [--user]" >&2
        return 1
    end

    set -l sudo sudo
    test $scope = --user; and set sudo

    set -l unit (systemctl $scope list-units --type=service --all --no-legend --plain \
        | awk '{ print $1, $3, $4 }' \
        | fzf --height 60% --reverse --prompt "systemd $action> " \
            --preview "systemctl $scope status --no-pager --lines 15 {1}" \
        | string split -f 1 ' ')
    test -n "$unit"; or return

    switch $action
        case status
            systemctl $scope status --no-pager $unit
        case logs
            if test $scope = --user
                journalctl --user -fu $unit
            else
                $sudo journalctl -fu $unit
            end
        case '*'
            $sudo systemctl $scope $action $unit
    end
end
