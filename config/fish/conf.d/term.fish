#
# term - terminal configuration
#

if test -n "$TERM_PROGRAM"
    set_term_var TERM_CURRENT_SHELL "fish $FISH_VERSION"
    set -gx COLORTERM truecolor

    if test "$TERM_PROGRAM" = WezTerm
        set -gx TERMINFO_DIRS $XDG_CONFIG_HOME/wezterm/terminfo
        set -gx WEZTERM_CONFIG_FILE $XDG_CONFIG_HOME/wezterm/wezterm.lua
    end

    if test "$TERM_PROGRAM" = WarpTerminal
        set -Ux COLORTERM truecolor
        set -e TERMINFO_DIRS
        # auto warpify subshells
        # printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish" }}\x9c'
    else
        # use atuin init for any terminal except WarpTerminal
        atuin init fish | source
    end
end
