function todo
  # outside the repo so every session and worktree shares it (see CLAUDE.md);
  # set TODO_FILE in config-local.fish to keep it elsewhere, e.g. an Obsidian vault
  set -l file (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/todo.md
  set -q TODO_FILE; and set file $TODO_FILE

  # exactly one flag-ish argument, so `todo help the user` is still an item
  if test (count $argv) -eq 1; and contains -- $argv[1] help -h --help
    echo "usage: todo                list the items, numbered
       todo <text>         add an open item
       todo rm <N>         delete item N
       todo archive        move done items to todo-done.md
       todo help           show this help

list: $file (override with TODO_FILE in config-local.fish)"
    return
  end

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

  # `todo archive` moves done items to todo-done.md next to the list; with more words it is still an item
  if test "$argv[1]" = archive; and test (count $argv) -eq 1
    set -l done (dirname $file)/todo-done.md
    test -f $file; or begin; echo "todo: nothing done to archive"; return; end
    set -l n (string match -r -- '^- \[x\].*' <$file | count)
    if test $n -eq 0
      echo "todo: nothing done to archive"
      return
    end
    # append before removing so a failure never loses items
    string match -r -- '^- \[x\].*' (cat $file) >> $done; or return 1
    string match -v -r -- '^- \[x\].*' (cat $file) >$file.tmp; and mv $file.tmp $file
    echo "todo: archived $n"
    return
  end

  mkdir -p (dirname $file)
  echo "- [ ] $argv" >> $file
end
