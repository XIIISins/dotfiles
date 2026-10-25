function fish_user_key_bindings
    # fzf
    bind \cf fzf_change_directory
    fzf_configure_bindings --directory=\co

    # ctrl-h is not backspace (the backspace key sends ^?, so only ctrl-h is affected)
    bind \ch ''

    #  # prevent iterm2 from closing when typing Ctrl-D (EOF)
    #  bind \cd delete-char
end
