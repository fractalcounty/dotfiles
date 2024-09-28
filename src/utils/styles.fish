#!/opt/homebrew/bin/fish
# Gum styles for setup.fish

set -gx STYLE_OK "✅"

# global colors
set -gx TEXT '#c0caf5'
set -gx INACTIVE_FG '#565f89'
set -gx INACTIVE_BG '#333955'
set -gx PURPLE '#bb9af7'
set -gx BLUE '#7aa2f7'
set -gx PALE '#b4f9f8'
set -gx ORANGE '#ff9e64'
set -gx RED '#f7768e'
set -gx GREEN '#9ece6a'

# gum style
set -gx FOREGROUND $BLUE
set -gx BORDER_FOREGROUND $BLUE
set -gx BOLD true

# gum spin
set -gx GUM_SPIN_TITLE_FOREGROUND $TEXT
set -gx GUM_SPIN_SPINNER_FOREGROUND $BLUE

# gum input
set -gx GUM_INPUT_CURSOR_FOREGROUND $TEXT
set -gx GUM_INPUT_PLACEHOLDER_FOREGROUND $INACTIVE_FG
set -gx GUM_INPUT_PROMPT_FOREGROUND $TEXT

# gum choose
set -gx GUM_CHOOSE_CURSOR_FOREGROUND $TEXT
set -gx GUM_CHOOSE_HEADER_FOREGROUND $TEXT
set -gx GUM_CHOOSE_SELECTED_FOREGROUND $TEXT
set -gx GUM_CHOOSE_ITEM_FOREGROUND $INACTIVE_FG

# gum confirm
set -gx GUM_CONFIRM_PROMPT_FOREGROUND $TEXT
set -gx GUM_CONFIRM_SELECTED_FOREGROUND $INACTIVE_BG
set -gx GUM_CONFIRM_SELECTED_BACKGROUND $BLUE
set -gx GUM_CONFIRM_UNSELECTED_FOREGROUND $INACTIVE_FG
set -gx GUM_CONFIRM_UNSELECTED_BACKGROUND $INACTIVE_BG

function format_code
    set -l input "$argv"
    echo (gum style --foreground "$TEXT" --background "$INACTIVE_BG" "$input")
end
