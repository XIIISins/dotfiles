function todo
  # outside the repo so every session and worktree shares it (see CLAUDE.md)
  set -l file (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/todo.md

  # no arguments: show the list instead of appending an empty item
  if test (count $argv) -eq 0
    test -f $file; and cat $file; or echo "todo: nothing yet"
    return
  end

  mkdir -p (dirname $file)
  echo "- [ ] $argv" >> $file
end
