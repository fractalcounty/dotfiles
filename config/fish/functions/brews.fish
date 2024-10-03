function brews --description "Show brewed formulae and casks"
    # Create a temporary file to store the output
    set -l temp_file (mktemp)

    # Header for Formulae
    echo (gum style --foreground "$theme_purple" --bold "Formulae:") >>$temp_file

    # Format and display formulae
    brew leaves | xargs brew deps --installed --for-each | while read -l line
        set -l parts (string split ': ' $line)
        set -l name $parts[1]
        set -l deps $parts[2]
        echo (gum style "• $name") (gum style --foreground "$theme_dark_gray" $deps) >>$temp_file
    end

    echo >>$temp_file

    # Header for Casks
    echo >>$temp_file
    echo (gum style --foreground "$theme_purple" --bold "Casks:") >>$temp_file

    # Format and display casks
    brew list --cask 2>/dev/null | sed 's/^/• /' | while read -l line
        echo (gum style "$line") >>$temp_file
    end

    # Display the output using gum pager
    gum pager --show-line-numbers=false --foreground="$theme_dark_gray" -th minimal <$temp_file

    # Clean up the temporary file
    rm $temp_file
end
