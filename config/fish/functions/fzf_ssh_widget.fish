function fzf_ssh_widget
    # ctrl+s: the binding replaces fish's pager search, so keep that in the completion menu
    if commandline --paging-mode
        commandline -f pager-toggle-search
        return
    end

    set -l host (fzf_ssh_host)
    if test -n "$host"
        # an empty line connects right away; execute (not running ssh here) keeps it in
        # history. Repaint first, so the prompt shows the command fzf drew over, and return:
        # a repaint queued after execute would land on the next prompt
        if not commandline | string trim | string length -q
            commandline -r "ssh $host"
            commandline -f repaint execute
            return
        else
            # otherwise the host goes in at the cursor (`scp file <C-s>:/tmp`); nothing runs
            commandline -i -- $host
        end
    end
    commandline -f repaint
end
