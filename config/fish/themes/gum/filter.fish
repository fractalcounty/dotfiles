function __gum_filter
    ## options
    set -gx GUM_FILTER_INDICATOR "•" # Character for selection
    set -gx GUM_FILTER_SELECTED_PREFIX " ◉ " # Character to indicate selected items (hidden if limit is 1)
    set -gx GUM_FILTER_UNSELECTED_PREFIX " ○ " # Character to indicate unselected items (hidden if limit is 1)
    set -gx GUM_FILTER_HEADER "" # Header value
    set -gx GUM_FILTER_PLACEHOLDER "Filter..." # Placeholder value
    set -gx GUM_FILTER_PROMPT "> " # Prompt to display
    set -gx GUM_FILTER_WIDTH 0 # Input width
    set -gx GUM_FILTER_HEIGHT 0 # Input height
    set -gx GUM_FILTER_VALUE "" # Initial filter value
    set -gx GUM_FILTER_REVERSE false # Display from the bottom of the screen
    set -gx GUM_FILTER_FUZZY true # Enable fuzzy matching
    set -gx GUM_FILTER_SORT true # Sort the results
    set -gx GUM_FILTER_TIMEOUT 0 # Timeout until filter command aborts

    ## style flags
    set -gx GUM_FILTER_INDICATOR_FOREGROUND $theme_blue
    set -e GUM_FILTER_INDICATOR_BACKGROUND
    set -gx GUM_FILTER_SELECTED_PREFIX_FOREGROUND $theme_blue
    set -e GUM_FILTER_SELECTED_PREFIX_BACKGROUND
    set -gx GUM_FILTER_UNSELECTED_PREFIX_FOREGROUND $theme_muted
    set -e GUM_FILTER_UNSELECTED_PREFIX_BACKGROUND
    set -gx GUM_FILTER_HEADER_FOREGROUND $theme_muted
    set -e GUM_FILTER_HEADER_BACKGROUND
    set -gx GUM_FILTER_TEXT_FOREGROUND $theme_normal
    set -e GUM_FILTER_TEXT_BACKGROUND
    set -gx GUM_FILTER_CURSOR_TEXT_FOREGROUND $theme_normal
    set -e GUM_FILTER_CURSOR_TEXT_BACKGROUND
    set -gx GUM_FILTER_MATCH_FOREGROUND $theme_blue
    set -e GUM_FILTER_MATCH_BACKGROUND
    set -gx GUM_FILTER_PROMPT_FOREGROUND $theme_muted
    set -e GUM_FILTER_PROMPT_BACKGROUND
    set -gx GUM_FILTER_PLACEHOLDER_FOREGROUND $theme_muted
    set -e GUM_FILTER_PLACEHOLDER_BACKGROUND
end
