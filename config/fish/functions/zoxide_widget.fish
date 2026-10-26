function zoxide_widget
    # ctrl+g: zoxide's interactive picker (zi). zi is only defined when zoxide is installed
    type -q zoxide; or return
    zi
    # repaint so the prompt shows the new directory and the typed command line survives
    commandline -f repaint
end
