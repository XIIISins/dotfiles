# TokyoNight Moon for tide's Rainbow style, built from the generated palette.
# Globals on purpose: conf.d/tide.fish sets the git colours with `set -g`, which
# shadows the universal values in tide-settings.fish. The name sorts after
# tide.fish so this wins. Palette variants: change the file name below.
set -l palette (path resolve (status dirname)/../../palette)/out/tokyonight-moon.fish
test -f $palette; or return
source $palette

# frame, separators
set -g tide_prompt_color_frame_and_connection $tn_comment
set -g tide_prompt_color_separator_same_color $tn_comment

# left prompt
set -g tide_os_bg_color $tn_fg_gutter
set -g tide_os_color $tn_blue
set -g tide_pwd_bg_color $tn_bg_highlight
set -g tide_pwd_color_anchors $tn_blue
set -g tide_pwd_color_dirs $tn_fg
set -g tide_pwd_color_truncated_dirs $tn_fg_dark
set -g tide_git_bg_color $tn_green
set -g tide_git_bg_color_unstable $tn_yellow
set -g tide_git_bg_color_urgent $tn_red
for part in branch conflicted dirty operation staged stash untracked upstream
    set -g tide_git_color_$part $tn_bg_dark
    set -g tide_git_{$part}_color $tn_bg_dark
end
set -g tide_character_color $tn_green
set -g tide_character_color_failure $tn_red

# right prompt
set -g tide_status_bg_color $tn_bg_highlight
set -g tide_status_color $tn_green
set -g tide_status_bg_color_failure $tn_red
set -g tide_status_color_failure $tn_bg_dark
set -g tide_cmd_duration_bg_color $tn_yellow
set -g tide_cmd_duration_color $tn_bg_dark
set -g tide_context_bg_color $tn_bg_highlight
set -g tide_context_color_default $tn_fg_dark
set -g tide_context_color_root $tn_yellow
set -g tide_context_color_ssh $tn_orange
set -g tide_jobs_bg_color $tn_bg_highlight
set -g tide_jobs_color $tn_green
set -g tide_time_bg_color $tn_fg_gutter
set -g tide_time_color $tn_fg_dark
set -g tide_vi_mode_bg_color_default $tn_comment
set -g tide_vi_mode_bg_color_insert $tn_cyan
set -g tide_vi_mode_bg_color_replace $tn_green
set -g tide_vi_mode_bg_color_visual $tn_orange
for mode in default insert replace visual
    set -g tide_vi_mode_color_$mode $tn_bg_dark
end

# tool items: one palette accent per tool, dark text
for pair in aws:orange crystal:fg_dark direnv:yellow distrobox:magenta docker:blue \
        elixir:magenta gcloud:blue go:cyan java:orange kubectl:blue nix_shell:cyan \
        node:green php:magenta private_mode:fg pulumi:yellow python:yellow \
        ruby:red rustc:orange shlvl:yellow terraform:magenta toolbox:magenta zig:yellow
    set -l item (string split : $pair)
    set -l accent tn_$item[2]
    set -g tide_{$item[1]}_bg_color $$accent
    set -g tide_{$item[1]}_color $tn_bg_dark
end
set -g tide_direnv_bg_color_denied $tn_red
set -g tide_direnv_color_denied $tn_bg_dark
