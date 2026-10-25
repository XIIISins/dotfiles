function fisher_outdated -d "List fish_plugins entries pinned behind the latest upstream tag or commit"
    # fish_plugins is pinned (owner/repo@ref). A tag pin is compared with the newest
    # upstream tag; comparing it with HEAD would flag every repo that has unreleased
    # commits. A commit pin is compared with HEAD.
    set -l file (dirname (dirname (status --current-filename)))/fish_plugins
    test -f $file; or return 1
    type -q git; or return 1

    set -l behind 0
    for line in (string match -rv '^\s*(#|$)' < $file)
        set -l parts (string split -- @ $line)
        set -q parts[2]; or continue # unpinned, nothing to compare

        # newest first; --refs drops the peeled ^{} entries of annotated tags
        set -l tags (command git ls-remote --tags --refs --sort=-v:refname \
      https://github.com/$parts[1].git 2>/dev/null | string replace -r '.*refs/tags/' '')

        if contains -- $parts[2] $tags
            test $parts[2] = $tags[1]; and continue
            echo "$parts[1]@$parts[2]: newer tag $tags[1]"
            set behind 1
            continue
        end

        set -l ahead (command curl -sL --connect-timeout 3 --max-time 10 \
      https://api.github.com/repos/$parts[1]/compare/$parts[2]...HEAD \
      | string match -rg '"ahead_by":\s*(\d+)')
        test -n "$ahead"; and test $ahead -gt 0; or continue
        echo "$parts[1]@$parts[2]: $ahead commits behind upstream"
        set behind 1
    end
    return $behind
end
