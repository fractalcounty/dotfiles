function paths --description 'Pretty print $PATH variables using gum'
    set path_list (string split ':' $PATH)
    set markdown_content
    for path in $path_list
        set -a markdown_content "- ``$path``"
    end
    printf '%s\n' $markdown_content | gum format
end
