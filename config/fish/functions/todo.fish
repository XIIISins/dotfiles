function todo
  # outside the repo so every session and worktree shares it (see CLAUDE.md)
  set -l file (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/todo.md

  # no arguments: show the list (numbered, for `todo rm`) instead of appending an empty item
  if test (count $argv) -eq 0
    test -f $file; and cat -n $file; or echo "todo: nothing yet"
    return
  end

  # `todo rm N` deletes line N; anything else starting with "rm" is still an item
  if test "$argv[1]" = rm; and test (count $argv) -eq 2; and string match -qr '^[0-9]+$' -- $argv[2]
    set -l n $argv[2]
    if not test -f $file; or test $n -lt 1; or test $n -gt (count (cat $file))
      echo "todo: no item $n" >&2
      return 1
    end
    sed -n "$n"p $file
    # temp file next to the list so the mv is atomic
    sed "$n"d $file >$file.tmp; and mv $file.tmp $file
    return
  end

  mkdir -p (dirname $file)
  echo "- [ ] $argv" >> $file
end
