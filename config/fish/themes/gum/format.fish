function __gum_format
    ## options
    # GUM_FORMAT_THEME is already set dynamically inside conf.d/theme.fish
    set -e GUM_FORMAT_LANGUAGE # Programming language to parse code
    set -gx GUM_FORMAT_TYPE markdown # Format to use (markdown,template,code,emoji)
end
