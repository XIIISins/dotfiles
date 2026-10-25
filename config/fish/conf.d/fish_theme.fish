# TokyoNight Moon for fish's own syntax highlighting and pager. Globals on purpose, and
# named so it loads after fish_frozen_theme.fish (fish's migrated stock ANSI colours),
# which it overrides. Palette variants: change the file name below.
set -l palette (path resolve (status dirname)/../../palette)/out/tokyonight-moon.fish
test -f $palette; or return
source $palette

set -g fish_color_normal $tn_fg
set -g fish_color_command $tn_blue
set -g fish_color_keyword $tn_magenta
set -g fish_color_param $tn_magenta
set -g fish_color_quote $tn_yellow
set -g fish_color_redirection $tn_fg
set -g fish_color_end $tn_orange
set -g fish_color_operator $tn_green
set -g fish_color_escape $tn_magenta
set -g fish_color_error $tn_red
set -g fish_color_comment $tn_comment
set -g fish_color_autosuggestion $tn_comment
set -g fish_color_valid_path --underline
set -g fish_color_cwd $tn_blue
set -g fish_color_cwd_root $tn_red
set -g fish_color_user $tn_green
set -g fish_color_host $tn_fg
set -g fish_color_host_remote $tn_yellow
set -g fish_color_status $tn_red
set -g fish_color_cancel -r
set -g fish_color_history_current --bold
set -g fish_color_selection --background=$tn_selection
set -g fish_color_search_match --background=$tn_selection

set -g fish_pager_color_prefix $tn_cyan --bold --underline
set -g fish_pager_color_completion $tn_fg_dark
set -g fish_pager_color_description $tn_comment
set -g fish_pager_color_progress $tn_comment
set -g fish_pager_color_selected_background --background=$tn_selection
