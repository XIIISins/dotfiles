function fzf_git_worktree
    git rev-parse --git-dir >/dev/null 2>&1; or begin
        echo "fzf_git_worktree: not in a git repository" >&2
        return 1
    end

    # --porcelain keeps paths with spaces intact
    set -l dir (git worktree list --porcelain \
        | string replace -r -f '^worktree ' '' \
        | fzf --height 40% --reverse --prompt 'worktree> ' \
            --preview 'git -C {} status -sb; echo; git -C {} log --oneline --color=always -10')
    test -n "$dir"; and cd -- $dir
end
