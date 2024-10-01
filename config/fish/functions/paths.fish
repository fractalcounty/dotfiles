function paths --description 'Prettify $PATH output using gum'
    # Split the $PATH and format each entry
    set path_list (string split ':' $PATH)

    # Print the header
    gum style --foreground 212 --bold "# Path variables:"

    # Style and print each path entry
    for path in $path_list
        gum style "$path" --style="code"
    end
end
