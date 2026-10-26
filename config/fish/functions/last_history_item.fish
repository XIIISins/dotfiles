function last_history_item
    # expands the `!!` abbreviation (config.fish) to the previous command
    echo $history[1]
end
