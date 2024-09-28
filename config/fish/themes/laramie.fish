# laramie theme

# main palette
set -gx foreground c0caf5 # #c0caf5
set -gx selection 283457 # #283457
set -gx comment 565f89 # #565f89
set -gx red f7768e # #f7768e
set -gx orange ff9e64 # #ff9e64
set -gx yellow e0af68 # #e0af68
set -gx green 9ece6a # #9ece6a   
set -gx purple 9d7cd8 # #9d7cd8
set -gx cyan 7dcfff # #7dcfff
set -gx pink bb9af7 # #bb9af7

# syntax highlighting
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_option $pink
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# completion pager
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
set -g fish_pager_color_selected_background --background=$selection
