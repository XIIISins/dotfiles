function fzf_docker
    # pick a running container, then act on it: sh (default), logs, restart or stop
    set -l action sh
    set -q argv[1]; and set action $argv[1]
    if not contains -- $action sh logs restart stop
        echo "usage: fzf_docker [sh|logs|restart|stop]" >&2
        return 1
    end

    set -l line (docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' \
        | fzf --height 40% --reverse --prompt "docker $action> " --delimiter '\t' \
            --preview 'docker logs --tail 30 {1} 2>&1')
    test -n "$line"; or return
    set -l name (string split -f 1 \t -- $line)

    switch $action
        case sh
            docker exec -it $name sh -c 'command -v bash >/dev/null && exec bash || exec sh'
        case logs
            docker logs -f --tail 100 $name
        case '*'
            docker $action $name
    end
end
