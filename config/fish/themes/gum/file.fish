function __gum_file
    ## arguments
    set -e GUM_FILE_PATH # The path to the directory to list

    ## options
    set -gx GUM_FILE_CURSOR "▶" # The cursor character
    set -gx GUM_FILE_ALL true # Show hidden and 'dot' files
    set -gx GUM_FILE_FILE true # Allow files selection
    set -gx GUM_FILE_DIRECTORY true # Allow directories selection
    set -gx GUM_FILE_SHOW_HELP true # Show help key binds
    set -e GUM_FILE_HEIGHT # Maximum number of files to display
    set -e GUM_FILE_TIMEOUT # Timeout until command aborts without a selection

    ## style flags
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
