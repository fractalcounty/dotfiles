function brews --description "Show brewed formulae and casks"
    # argument parsing
    set -l options (fish_opt --short=r --long=raw)
    argparse $options -- $argv
    or return 1 # handle parsing errors

    # Create a temporary file to store the output
    set -l temp_file (mktemp)

    # Header for Formulae
    echo (gum style --foreground "$theme_purple" --bold "Formulae:") >>$temp_file

    # Format and display formulae, suppressing name clash warnings
    # and adding brackets around dependencies
    brew leaves | xargs brew deps --formula --installed --for-each | while read -l line
        set -l parts (string split ': ' $line)
        set -l name $parts[1]
        set -l deps $parts[2]
        #* add brackets and style dependencies
        set -l styled_deps (gum style --foreground "$theme_dark_gray" "[$deps]")
        echo (gum style "• $name") $styled_deps >>$temp_file
    end

    echo >>$temp_file

    # Header for Casks
    echo >>$temp_file
    echo (gum style --foreground "$theme_purple" --bold "Casks:") >>$temp_file

    # Format and display casks
    brew list --cask 2>/dev/null | sed 's/^/• /' | while read -l line
        echo (gum style "$line") >>$temp_file
    end

    # Display the output using gum pager or raw cat
    if set -q _flag_raw
        cat $temp_file
    else
        gum pager --show-line-numbers=false --foreground="$theme_dark_gray" -th minimal <$temp_file
    end

    # Clean up the temporary file
    rm $temp_file
end
