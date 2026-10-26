# TokyoNight Moon for fzf (fzf.fish uses it too) and eza. Set from scratch rather than
# appended to, so child shells that inherit the exported value do not stack it up.
set -l palette (path resolve (status dirname)/../../palette)/out/tokyonight-moon.fish
test -f $palette; or return
source $palette

# bg is -1 (terminal default) so ghostty's background shows through, like nvim.
# The layout is here too: setting FZF_DEFAULT_OPTS makes fzf.fish skip its own defaults, so
# every picker (ctrl+s/f/o, fb, fw) shares this one look instead of choosing its own
set -gx FZF_DEFAULT_OPTS "--cycle --layout=reverse --border --height=60% --preview-window=wrap --marker=* --color=fg:#$tn_fg,bg:-1,hl:#$tn_blue,fg+:#$tn_fg,bg+:#$tn_selection,hl+:#$tn_cyan,info:#$tn_yellow,prompt:#$tn_cyan,pointer:#$tn_cyan,marker:#$tn_green,spinner:#$tn_orange,header:#$tn_orange,border:#$tn_fg_gutter,gutter:-1"

# eza: SGR truecolor per file type and column, only where the default clashes with the palette
set -l c 38\;2\;
set -gx EZA_COLORS "di=$c$tn_blue_rgb:ex=$c$tn_green_rgb:ln=$c$tn_cyan_rgb:or=$c$tn_red_rgb:da=$c$tn_comment_rgb:sn=$c$tn_green_rgb:sb=$c$tn_orange_rgb:uu=$c$tn_yellow_rgb:un=$c$tn_orange_rgb:gu=$c$tn_yellow_rgb:gn=$c$tn_orange_rgb:ur=$c$tn_yellow_rgb:uw=$c$tn_red_rgb:ux=$c$tn_green_rgb:ue=$c$tn_green_rgb:gr=$c$tn_yellow_rgb:gw=$c$tn_red_rgb:gx=$c$tn_green_rgb:tr=$c$tn_yellow_rgb:tw=$c$tn_red_rgb:tx=$c$tn_green_rgb"
