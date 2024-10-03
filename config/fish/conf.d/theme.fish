set -gx DARK_THEME laramie
set -gx LIGHT_THEME casper

set -q THEME; or set -gx THEME $DARK_THEME
set -q APPEARANCE; or set -gx APPEARANCE dark

set -gx THEME_FILE $__fish_themes_dir/$THEME.fish
source $__fish_themes_dir/laramie.fish

# gum
set -gx GLAMOUR_STYLE $__fish_themes_dir/$THEME.json
set -gx GUM_FORMAT_THEME $__fish_themes_dir/$THEME.json
set -gx GUM_THEMES_DIR $__fish_themes_dir/gum; and mkdir -p $GUM_THEMES_DIR

# Less colors
set -gx LESS_TERMCAP_mb (set_color -o blue)
set -gx LESS_TERMCAP_md (set_color -o cyan)
set -gx LESS_TERMCAP_me (set_color normal)
set -gx LESS_TERMCAP_so (set_color -b white black)
set -gx LESS_TERMCAP_se (set_color normal)
set -gx LESS_TERMCAP_us (set_color -u magenta)
set -gx LESS_TERMCAP_ue (set_color normal)

# syntax highlighting
set -g fish_color_normal $theme_foreground # General text
set -g fish_color_command $theme_blue # Commands (function names)
set -g fish_color_keyword $theme_purple # Control keywords (e.g., if, while)
set -g fish_color_quote $theme_green # Strings
set -g fish_color_redirection $theme_orange # Redirection operators (e.g., >, >>)
set -g fish_color_end $theme_foreground # End of command (; or &)
set -g fish_color_option $theme_light_blue # Command options/flags
set -g fish_color_error $theme_red # Error messages
set -g fish_color_param $theme_white # Parameters
set -g fish_color_comment $theme_dark_gray # Comments
set -g fish_color_match $theme_yellow --background=$theme_dust # Matching text in completions
set -g fish_color_search_match $theme_light_cyan --background=$theme_dust # Matches in search
set -g fish_color_operator $theme_cyan # Operators (+, -, |, etc.)
set -g fish_color_escape $theme_light_green # Escape sequences (e.g., \n, \t)
set -g fish_color_cwd $theme_light_blue # Current working directory
set -g fish_color_autosuggestion $theme_gray # Autosuggestion text
set -g fish_color_user $theme_light_cyan # Username
set -g fish_color_host $theme_light_green # Hostname

# completion pager
set -g fish_pager_color_progress $theme_foreground
set -e fish_pager_color_background
set -g fish_pager_color_prefix $theme_foreground
set -g fish_pager_color_completion $theme_light_blue
set -g fish_pager_color_description $theme_foreground
set -g fish_pager_color_selected_prefix $theme_green
set -g fish_pager_color_selected_completion $theme_light_green --background=$theme_dust
set -g fish_pager_color_selected_description $theme_red # Selected description
set -g fish_pager_color_secondary_prefix $theme_red # Secondary prefix
set -g fish_pager_color_secondary_completion $theme_background # Secondary completion
set -g fish_pager_color_secondary_description $theme_light_blue # Secondary description

# bat style
set -gx BAT_STYLE 'header,header-filename,rule,numbers,snip'

function update_appearance
    set -l interface_style (defaults read -g AppleInterfaceStyle 2>/dev/null)
    if test "$interface_style" = Dark
        _dark_theme
    else
        _light_theme
    end
end

function _dark_theme
    source "$THEME_FILE"

    set -gx APPEARANCE dark
    set -gx CURRENT_THEME $DARK_THEME
    set -gx BAT_THEME "$DARK_THEME"
end

function _light_theme
    source "$THEME_FILE"

    set -gx APPEARANCE light
    set -gx CURRENT_THEME $LIGHT_THEME
    set -gx BAT_THEME "$LIGHT_THEME"
end

# Initial setup
if status --is-interactive
    update_appearance
end
