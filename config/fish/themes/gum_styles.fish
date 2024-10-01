function __gum_choose
    set -gx GUM_CHOOSE_CURSOR "👉 "
    set -gx GUM_CHOOSE_CURSOR_FOREGROUND $theme_normal
    set -e GUM_CHOOSE_CURSOR_BACKGROUND
    set -gx GUM_CHOOSE_HEADER_FOREGROUND $theme_normal
    set -e GUM_CHOOSE_HEADER_BACKGROUND
    set -gx GUM_CHOOSE_ITEM_FOREGROUND $theme_comment
    set -e GUM_CHOOSE_ITEM_BACKGROUND
    set -gx GUM_CHOOSE_SELECTED_FOREGROUND $theme_normal
    set -e GUM_CHOOSE_SELECTED_BACKGROUND
end

function __gum_confirm
    set -gx GUM_CONFIRM_PROMPT_FOREGROUND $theme_normal
    set -e GUM_CONFIRM_PROMPT_BACKGROUND
    set -gx GUM_CONFIRM_SELECTED_FOREGROUND $theme_comment
    set -e GUM_CONFIRM_SELECTED_BACKGROUND $theme_blue
    set -gx GUM_CONFIRM_UNSELECTED_FOREGROUND $theme_comment
    set -gx GUM_CONFIRM_UNSELECTED_BACKGROUND $theme_comment
end

function __gum_file
    set -gx GUM_FILE_CURSOR_FOREGROUND $theme_blue
    set -e GUM_FILE_CURSOR_BACKGROUND
    set -gx GUM_FILE_SYMLINK_FOREGROUND $theme_cyan
    set -e GUM_FILE_SYMLINK_BACKGROUND
    set -gx GUM_FILE_DIRECTORY_FOREGROUND $theme_purple
    set -e GUM_FILE_DIRECTORY_BACKGROUND
    set -gx GUM_FILE_FILE_FOREGROUND $theme_normal
    set -e GUM_FILE_FILE_BACKGROUND
    set -gx GUM_FILE_PERMISSIONS_FOREGROUND $theme_comment
    set -e GUM_FILE_PERMISSIONS_BACKGROUND
    set -gx GUM_FILE_SELECTED_FOREGROUND $theme_blue
    set -e GUM_FILE_SELECTED_BACKGROUND
    set -gx GUM_FILE_FILE_SIZE_FOREGROUND $theme_muted
    set -e GUM_FILE_FILE_SIZE_BACKGROUND
end

function __gum_filter
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

function __gum_format
    # set -e GUM_FORMAT_THEME dynamically set inside conf.d/theme.fish
    set -e GUM_FORMAT_LANGUAGE
    set -gx GUM_FORMAT_TYPE markdown
end

function __gum_style
    set -e BACKGROUND
    set -e BORDER
    set -e BORDER_BACKGROUND
    set -e BORDER_FOREGROUND
    set -e ALIGN
    set -e HEIGHT
    set -e WIDTH
    set -e MARGIN
    set -e PADDING
    set -e BOLD
    set -e FAINT
    set -e ITALIC
    set -e STRIKETHROUGH
    set -e UNDERLINE
    set -gx FOREGROUND $theme_normal
end

function __gum_style_title
    set -gx FOREGROUND $theme_blue
    set -gx BORDER rounded
    set -gx BORDER_FOREGROUND $theme_blue
    set -gx PADDING "1 2"
    set -gx MARGIN "1 0"
    set -gx BOLD true
end

function __gum_style_section
    set -gx FOREGROUND $theme_blue
    set -gx PADDING "1 0"
    set -gx BOLD true
end

function __gum_style_text
    set -gx FOREGROUND $theme_normal
end

function __gum_style_code
    set -gx FOREGROUND $theme_light_blue
end

function __gum_spin
    set -gx GUM_SPIN_SPINNER_FOREGROUND $theme_blue
    set -e GUM_SPIN_SPINNER_BACKGROUND
    set -gx GUM_SPIN_TITLE_FOREGROUND $theme_normal
    set -e GUM_SPIN_TITLE_BACKGROUND
end

function __gum_input
    set -e GUM_INPUT_PROMPT_FOREGROUND
    set -e GUM_INPUT_PROMPT_BACKGROUND $theme_normal
    set -gx GUM_INPUT_PLACEHOLDER_FOREGROUND $theme_comment
    set -e GUM_INPUT_PLACEHOLDER_BACKGROUND
    set -gx GUM_INPUT_CURSOR_FOREGROUND $theme_normal
    set -e GUM_INPUT_CURSOR_BACKGROUND
    set -e GUM_INPUT_HEADER_FOREGROUND
    set -e GUM_INPUT_HEADER_BACKGROUND
end

function __gum_log
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
end
