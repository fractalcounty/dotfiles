function __gum_write
    ## options
    set -e GUM_WRITE_WIDTH # text area width (0 for terminal width)
    set -gx GUM_WRITE_HEIGHT 5 # text area height
    set -e GUM_WRITE_HEADER # header value
    set -gx GUM_WRITE_PLACEHOLDER "Write something..." # placeholder value
    set -gx GUM_WRITE_PROMPT "┃ " # prompt to display
    set -e GUM_WRITE_SHOW_CURSOR_LINE # show cursor line
    set -e GUM_WRITE_SHOW_LINE_NUMBERS # show line numbers
    set -e GUM_WRITE_VALUE # initial value (can be passed via stdin)
    set -e GUM_WRITE_SHOW_HELP # show help key binds
    set -gx GUM_WRITE_CURSOR_MODE blink # cursor mode

    ## style flags
    set -e GUM_WRITE_BASE_FOREGROUND
    set -e GUM_WRITE_BASE_BACKGROUND
    set -gx GUM_WRITE_CURSOR_FOREGROUND 212
    set -e GUM_WRITE_CURSOR_BACKGROUND
    set -gx GUM_WRITE_HEADER_FOREGROUND 240
    set -e GUM_WRITE_HEADER_BACKGROUND
    set -gx GUM_WRITE_PLACEHOLDER_FOREGROUND 240
    set -e GUM_WRITE_PLACEHOLDER_BACKGROUND
    set -gx GUM_WRITE_PROMPT_FOREGROUND 7
    set -e GUM_WRITE_PROMPT_BACKGROUND
    set -gx GUM_WRITE_END_OF_BUFFER_FOREGROUND 0
    set -e GUM_WRITE_END_OF_BUFFER_BACKGROUND
    set -gx GUM_WRITE_LINE_NUMBER_FOREGROUND 7
    set -e GUM_WRITE_LINE_NUMBER_BACKGROUND
    set -gx GUM_WRITE_CURSOR_LINE_NUMBER_FOREGROUND 7
    set -e GUM_WRITE_CURSOR_LINE_NUMBER_BACKGROUND
    set -e GUM_WRITE_CURSOR_LINE_FOREGROUND
    set -e GUM_WRITE_CURSOR_LINE_BACKGROUND
end
