function __gum_pager
    ## options
    set -e GUM_PAGER_TIMEOUT # timeout until command exits

    ## style flags
    set -gx GUM_PAGER_FOREGROUND $theme_foreground
    set -e GUM_PAGER_BACKGROUND
    set -gx GUM_PAGER_HELP_FOREGROUND $theme_dark_gray
    set -e GUM_PAGER_HELP_BACKGROUND
    set -gx GUM_PAGER_LINE_NUMBER_FOREGROUND 237
    set -e GUM_PAGER_LINE_NUMBER_BACKGROUND
    set -gx GUM_PAGER_MATCH_FOREGROUND $theme_white
    set -gx GUM_PAGER_MATCH_BACKGROUND $theme_dust
    set -gx GUM_PAGER_MATCH_HIGH_FOREGROUND $theme_purple
    set -gx GUM_PAGER_MATCH_HIGH_BACKGROUND $theme_dust
end

function __gum_pager_minimal
    ## options
    set -e GUM_PAGER_TIMEOUT # timeout until command exits

    ## style flags
    set -gx GUM_PAGER_FOREGROUND $theme_foreground
    set -gx GUM_PAGER_HELP_FOREGROUND $theme_dark_gray
    set -gx GUM_PAGER_MATCH_FOREGROUND $theme_white
    set -gx GUM_PAGER_MATCH_BACKGROUND $theme_dust
    set -gx GUM_PAGER_MATCH_HIGH_FOREGROUND $theme_purple
    set -gx GUM_PAGER_MATCH_HIGH_BACKGROUND $theme_dust
end
