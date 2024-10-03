function __gum_log
    ## style flags
    set -e GUM_LOG_LEVEL_FOREGROUND
    set -e GUM_LOG_LEVEL_BACKGROUND
    set -e GUM_LOG_TIME_FOREGROUND
    set -e GUM_LOG_TIME_BACKGROUND
    set -e GUM_LOG_PREFIX_FOREGROUND
    set -e GUM_LOG_PREFIX_BACKGROUND
    set -e GUM_LOG_MESSAGE_FOREGROUND
    set -e GUM_LOG_MESSAGE_BACKGROUND
    set -e GUM_LOG_KEY_FOREGROUND
    set -e GUM_LOG_KEY_BACKGROUND
    set -e GUM_LOG_VALUE_FOREGROUND
    set -e GUM_LOG_VALUE_BACKGROUND
    set -e GUM_LOG_SEPARATOR_FOREGROUND
    set -e GUM_LOG_SEPARATOR_BACKGROUND

    ## custom variables
    ## format: GUM_LOG_LEVEL_<level>
    set -gx GUM_LOG_LEVEL_DEBUG $theme_dark_gray # if 'gum log -l debug [message]', appends '--'
    set -gx GUM_LOG_LEVEL_INFO $theme_blue # if 'gum log -l info [message]'
    set -gx GUM_LOG_LEVEL_WARN $theme_orange # if 'gum log -l warn [message]'
    set -gx GUM_LOG_LEVEL_ERROR $theme_red # if 'gum log -l error [message]'
    set -gx GUM_LOG_LEVEL_FATAL $theme_red # if 'gum log -l fatal [message]'
end
