function __gum_input
    ## options
    set -e GUM_INPUT_PLACEHOLDER # placeholder text
    set -e GUM_INPUT_PROMPT # prompt to display
    set -e GUM_INPUT_CURSOR_MODE # blink, hide, static
    set -e GUM_INPUT_WIDTH # input width (0 for terminal width)
    set -gx GUM_INPUT_SHOW_HELP true # show help keybinds
    set -e GUM_INPUT_HEADER # header value
    set -e GUM_INPUT_TIMEOUT # timeout until input aborts

    ## style flags
    set -e GUM_INPUT_PROMPT_FOREGROUND
    set -e GUM_INPUT_PROMPT_BACKGROUND $theme_normal
    set -gx GUM_INPUT_PLACEHOLDER_FOREGROUND $theme_comment
    set -e GUM_INPUT_PLACEHOLDER_BACKGROUND
    set -gx GUM_INPUT_CURSOR_FOREGROUND $theme_normal
    set -e GUM_INPUT_CURSOR_BACKGROUND
    set -e GUM_INPUT_HEADER_FOREGROUND
    set -e GUM_INPUT_HEADER_BACKGROUND
end
