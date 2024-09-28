set -gx DARK_THEME laramie
set -gx LIGHT_THEME casper
set -g DARK_THEME_FILE $__fish_config_dir/themes/$DARK_THEME.fish
set -g LIGHT_THEME_FILE $__fish_config_dir/themes/$LIGHT_THEME.fish

# Less colors
set -gx LESS_TERMCAP_mb (set_color -o blue)
set -gx LESS_TERMCAP_md (set_color -o cyan)
set -gx LESS_TERMCAP_me (set_color normal)
set -gx LESS_TERMCAP_so (set_color -b white black)
set -gx LESS_TERMCAP_se (set_color normal)
set -gx LESS_TERMCAP_us (set_color -u magenta)
set -gx LESS_TERMCAP_ue (set_color normal)

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
    echo "Setting dark theme"
    source "$DARK_THEME_FILE"

    set -gx APPEARANCE dark
    set -gx CURRENT_THEME $DARK_THEME
    set -gx BAT_THEME "$DARK_THEME"
end

function _light_theme
    echo "Setting light theme"
    source "$LIGHT_THEME_FILE"

    set -gx APPEARANCE light
    set -gx CURRENT_THEME $LIGHT_THEME
    set -gx BAT_THEME "$LIGHT_THEME"
end

function start_appearance_watcher
    if set -q appearance_watcher_pid
        return
    end

    if type -q fswatch
        fish -c '
        while true
            if fswatch -1 ~/Library/Preferences/.GlobalPreferences.plist >/dev/null 2>&1
                update_appearance
            else
                sleep 5
            end
        end
        ' &
    else
        fish -c '
        while true
            sleep 3
            update_appearance
        end
        ' &
    end

    set -g appearance_watcher_pid (jobs -lp | tail -n1)
end

# Initial setup
if status --is-interactive
    update_appearance
    start_appearance_watcher
end
