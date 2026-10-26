function fzf_ssh_widget
    # ctrl+s: the binding replaces fish's pager search, so keep that in the completion menu
    if commandline --paging-mode
        commandline -f pager-toggle-search
        return
    end

    set -l host (fzf_ssh_host)
    if test -n "$host"
        # an empty line becomes `ssh <host>`, otherwise the host goes in at the cursor
        # (`scp file <C-s>:/tmp`). Nothing runs until Enter, as with ctrl+r
        if not commandline | string trim | string length -q
            commandline -r "ssh $host"
        else
            commandline -i -- $host
        end
    end
    commandline -f repaint
end
