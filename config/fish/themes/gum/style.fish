function __gum_style
    ## style flags
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
    set -gx FOREGROUND $theme_foreground
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
    set -gx BORDER rounded
    set -gx BORDER_FOREGROUND $theme_blue
    set -gx PADDING "0 2"
    set -gx MARGIN "1 0 0 0"
    set -gx BOLD true
end

function __gum_style_prompt
    set -gx FOREGROUND $theme_foreground
    set -gx MARGIN "1 1"
    set -gx BOLD false
end

function __gum_style_text
    set -gx FOREGROUND $theme_foreground
end

function __gum_style_code
    set -gx FOREGROUND $theme_white
    set -gx BACKGROUND $theme_dust
end

function __gum_style_output
    set -gx FOREGROUND $theme_dark_gray
    set -gx BACKGROUND $theme_black
end
