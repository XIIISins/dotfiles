function fisher_outdated -d "List fish_plugins entries with newer upstream commits"
  # fish_plugins is pinned (owner/repo@ref); ask GitHub how far HEAD is ahead of each pin
  set -l file (dirname (dirname (status --current-filename)))/fish_plugins
  test -f $file; or return 1

  set -l behind 0
  for line in (string match -rv '^\s*(#|$)' < $file)
    set -l parts (string split -- @ $line)
    set -q parts[2]; or continue # unpinned, nothing to compare
    set -l ahead (command curl -sL --connect-timeout 3 --max-time 10 \
      https://api.github.com/repos/$parts[1]/compare/$parts[2]...HEAD \
      | string match -rg '"ahead_by":\s*(\d+)')
    test -n "$ahead"; and test $ahead -gt 0; or continue
    echo "$parts[1]@$parts[2]: $ahead commits behind upstream"
    set behind 1
  end
  return $behind
end
