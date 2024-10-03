function __gum_choose
    ## options
    set -gx GUM_CHOOSE_ORDERED true # Maintain the order of the selected options
    set -e GUM_CHOOSE_HEIGHT # Height of the list
    set -gx GUM_CHOOSE_CURSOR "▶ " # Prefix to show on item that corresponds to the cursor position
    set -gx GUM_CHOOSE_SHOW_HELP true # Show help keybinds
    set -gx GUM_CHOOSE_HEADER "Choose an option:" # Header value
    set -gx GUM_CHOOSE_CURSOR_PREFIX "• " # Prefix to show on the cursor item (hidden if limit is 1)
    set -gx GUM_CHOOSE_SELECTED_PREFIX "✓ " # Prefix to show on selected items (hidden if limit is 1)
    set -gx GUM_CHOOSE_UNSELECTED_PREFIX "• " # Prefix to show on unselected items (hidden if limit is 1)
    set -e GUM_CHOOSE_SELECTED # Options that should start as selected
    set -e GUM_CHOOSE_TIMEOUT # Timeout until choose returns selected element

    ## style flags
    set -gx GUM_CHOOSE_CURSOR_FOREGROUND $theme_purple
    set -e GUM_CHOOSE_CURSOR_BACKGROUND
    set -gx GUM_CHOOSE_HEADER_FOREGROUND $theme_purple
    set -e GUM_CHOOSE_HEADER_BACKGROUND
    set -gx GUM_CHOOSE_ITEM_FOREGROUND $theme_gray
    set -e GUM_CHOOSE_ITEM_BACKGROUND
    set -gx GUM_CHOOSE_SELECTED_FOREGROUND $theme_purple
    set -e GUM_CHOOSE_SELECTED_BACKGROUND
end
