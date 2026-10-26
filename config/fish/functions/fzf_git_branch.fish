function fzf_git_branch
    git rev-parse --git-dir >/dev/null 2>&1; or begin
        echo "fzf_git_branch: not in a git repository" >&2
        return 1
    end

    # newest first; the full ref name is needed to drop <remote>/HEAD, whose short name is just <remote>
    set -l branch (git for-each-ref --sort=-committerdate --format='%(refname)' refs/heads refs/remotes \
        | string match -v -r '/HEAD$' \
        | string replace -r '^refs/(heads|remotes)/' '' \
        | fzf --height 40% --reverse --prompt 'branch> ' \
            --preview 'git log --oneline --color=always -20 {}')
    test -n "$branch"; or return

    # origin/foo -> foo: switch then creates a local branch tracking it
    for remote in (git remote)
        if string match -q -- "$remote/*" $branch
            set branch (string replace -- "$remote/" '' $branch)
            break
        end
    end
    git switch $branch
end
