function gum --description "Gum wrapper that sets up the theme before running the command" --wraps gum

    # gum style
    set -lx FOREGROUND $BLUE
    set -lx BORDER_FOREGROUND $BLUE
    set -lx BOLD true

    # gum spin
    set -lx GUM_SPIN_TITLE_FOREGROUND $TEXT
    set -lx GUM_SPIN_SPINNER_FOREGROUND $BLUE

    # gum input
    set -lx GUM_INPUT_CURSOR_FOREGROUND $TEXT
    set -lx GUM_INPUT_PLACEHOLDER_FOREGROUND $INACTIVE_FG
    set -lx GUM_INPUT_PROMPT_FOREGROUND $TEXT

    # gum choose
    set -lx GUM_CHOOSE_CURSOR_FOREGROUND $TEXT
    set -lx GUM_CHOOSE_HEADER_FOREGROUND $TEXT
    set -lx GUM_CHOOSE_SELECTED_FOREGROUND $TEXT
    set -lx GUM_CHOOSE_ITEM_FOREGROUND $INACTIVE_FG

    # gum confirm
    set -lx GUM_CONFIRM_PROMPT_FOREGROUND $TEXT
    set -lx GUM_CONFIRM_SELECTED_FOREGROUND $INACTIVE_BG
    set -lx GUM_CONFIRM_SELECTED_BACKGROUND $BLUE
    set -lx GUM_CONFIRM_UNSELECTED_FOREGROUND $INACTIVE_FG
    set -lx GUM_CONFIRM_UNSELECTED_BACKGROUND $INACTIVE_BG

    command gum $argv
end
