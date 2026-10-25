function fzf_kube
    # switch the kubectl context (default) or the namespace of the current one
    set -l what ctx
    set -q argv[1]; and set what $argv[1]
    if not contains -- $what ctx ns
        echo "usage: fzf_kube [ctx|ns]" >&2
        return 1
    end

    switch $what
        case ctx
            set -l ctx (kubectl config get-contexts -o name | fzf --height 40% --reverse --prompt 'context> ')
            test -n "$ctx"; and kubectl config use-context $ctx
        case ns
            set -l ns (kubectl get namespaces -o name | string replace 'namespace/' '' \
                | fzf --height 40% --reverse --prompt 'namespace> ')
            test -n "$ns"; and kubectl config set-context --current --namespace $ns
    end
end
