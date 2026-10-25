function fzf_change_directory
    # fzf has to sit in the same pipeline as the candidate list; a separate
    # helper doing `set dir (fzf)` ends up reading the terminal instead of the pipe
    set -l dir (begin
    echo $HOME/.config
    if type -q ghq; and test -d (ghq root)
      find (ghq root) -maxdepth 4 -type d -name .git | sed 's/\/\.git$//'
    end
    find $PWD -mindepth 1 -maxdepth 1 -type d ! -name '.*'
    if test -d $HOME/Dev
      find $HOME/Dev -mindepth 2 -maxdepth 2 -type d ! -name '.*'
    end
  end | awk '!a[$0]++' | fzf $argv)

    # keep what was typed: cancelling must not wipe the command line
    test -n "$dir"; and builtin cd -- $dir
    commandline -f repaint
end
