#!/opt/homebrew/bin/fish
# Improved brews function with gum styling

function brews --description "Show brewed formulae and casks"
    set -l formulae (brew leaves | xargs brew deps --installed --for-each)
    set -l casks (brew list --cask 2>/dev/null)

    # Header for Formulae
    gum style --foreground "$BLUE" --bold --margin "0 0" --padding "0 5" --border normal --border-foreground "$BLUE" Formulae

    # Format and display formulae
    for line in $formulae
        set -l parts (string split ':' $line)
        set -l name $parts[1]
        set -l deps $parts[2]

        echo (gum style --foreground normal $name) \
            (gum style --foreground "$INACTIVE_FG" $deps)
    end

    echo

    # Header for Casks
    gum style --foreground "$BLUE" --bold --margin "0 0" --padding "0 5" --border normal --border-foreground "$BLUE" Casks

    # Format and display casks
    for cask in $casks
        gum style --foreground normal $cask
    end
end
