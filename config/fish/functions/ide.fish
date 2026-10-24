function ide
  if test (count $argv) -eq 1; and contains -- $argv[1] help -h --help
    echo "usage: ide [path]   open the dev layout for a repo (default: current directory)

nvim top, claude right, terminals bottom, all in the repo root. Reuses the
repo's window if it is already open. claude resumes the last session when it
is under an hour old, otherwise it starts fresh."
    return
  end

  set -l dir $PWD
  test (count $argv) -gt 0; and set dir (path resolve $argv[1])
  test -f $dir; and set dir (path dirname $dir)
  if not test -d $dir
    echo "ide: no such directory: $dir" >&2
    return 1
  end

  # any path inside a repo opens the repo; outside one it opens the folder itself
  set -l root (git -C $dir rev-parse --show-toplevel 2>/dev/null); or set root $dir
  set -l name (path basename $root)

  # claude keeps sessions per directory, named like the path with / and . as -
  set -l claude claude
  set -l sessions $HOME/.claude/projects/(string replace -a -r '[/.]' - $root)
  if test -d $sessions; and test (count (find $sessions -maxdepth 1 -name '*.jsonl' -mmin -60 2>/dev/null)) -gt 0
    set claude claude --continue
  end

  # tmux session names cannot contain . or :
  set -l sess (string replace -a -r '[.:]' _ $name)

  set -l win
  if set -q TMUX
    # the window already made for this repo (tagged below)
    for line in (tmux list-windows -F '#{window_id} #{@ide-root}')
      set -l parts (string split -m1 ' ' -- $line)
      if test "$parts[2]" = "$root"
        tmux select-window -t $parts[1]
        return
      end
    end
    set win (tmux new-window -d -P -F '#{window_id}' -n $name -c $root)
  else
    if tmux has-session -t =$sess 2>/dev/null
      tmux attach -t =$sess
      return
    end
    set win (tmux new-session -d -P -F '#{window_id}' -s $sess -n $name -c $root)
  end

  tmux set-option -w -t $win @ide-root $root
  ~/.config/tmux/layouts.sh apply $win dev

  # panes keep layout order: the first is the big top one, the last the narrow right one
  set -l panes (tmux list-panes -t $win -F '#{pane_id}')
  tmux send-keys -t $panes[1] nvim Enter
  if test (count $panes) -gt 1
    tmux send-keys -t $panes[-1] "$claude" Enter
    tmux select-pane -t $panes[-1]
  end

  if set -q TMUX
    tmux select-window -t $win
  else
    tmux attach -t =$sess
  end
end
