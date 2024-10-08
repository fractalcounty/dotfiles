function __gum_confirm
    ## options
    set -gx GUM_CONFIRM_SHOW_HELP false # Show help key binds
    set -e GUM_CONFIRM_TIMEOUT # Timeout until confirm returns selected value or default if provided

    ## style flags
    set -gx GUM_CONFIRM_PROMPT_FOREGROUND $theme_blue
    set -e GUM_CONFIRM_PROMPT_BACKGROUND
    set -gx GUM_CONFIRM_SELECTED_FOREGROUND $theme_background
    set -gx GUM_CONFIRM_SELECTED_BACKGROUND $theme_blue
    set -gx GUM_CONFIRM_UNSELECTED_FOREGROUND $theme_light_gray
    set -gx GUM_CONFIRM_UNSELECTED_BACKGROUND $theme_dust
end

function __gum_confirm_alt
    set -gx GUM_CONFIRM_SHOW_HELP false # Show help key binds
    set -gx GUM_CONFIRM_PROMPT_FOREGROUND $theme_purple
    set -gx GUM_CONFIRM_SELECTED_BACKGROUND $theme_purple
end
