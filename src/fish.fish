#!/opt/homebrew/bin/fish
# fish.fish - fish shell configuration script

function format_output
    echo
    gum style --border none --foreground "$TEXT" --background "$INACTIVE_BG"
    echo
end

log_message $DEBUG "Starting initialization process..."

set -l formatted_shells (gum style --foreground "$TEXT" --background "$INACTIVE_BG" "/etc/shells")
log_message $DEBUG "Ensuring fish is in $formatted_shells..."
if not grep -q /opt/homebrew/bin/fish /etc/shells
    echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells >/dev/null
    if test $status -ne 0
        log_message $ERROR "Failed to add fish to $formatted_shells"
        exit 1
    end
    log_message $INFO "Added fish to $formatted_shells"
else
    log_message $INFO "Fish is in $formatted_shells"
end

log_message $DEBUG "Ensuring fish is the default shell..."
if not string match -q "*fish" $SHELL
    if not sudo chsh -s /opt/homebrew/bin/fish $USER
        log_message $ERROR "Failed to set fish as the default shell."
        exit 1
    end
    log_message $INFO "Fish shell has been set as the default shell."
else
    log_message $INFO "Fish is the default shell."
end

log_message $DEBUG "Ensuring homebrew's binaries are in the fish path..."
if not contains /opt/homebrew/bin $fish_user_paths
    fish_add_path /opt/homebrew/bin
    if test $status -ne 0
        log_message $ERROR "Failed to add Homebrew's binaries to fish PATH."
        exit 1
    end
    log_message $INFO "Homebrew's binaries have been added to fish PATH."
else
    log_message $DEBUG "Homebrew's binaries are in the fish PATH."
end

log_message $DEBUG "Attempting to create fish completion files..."
if not gum spin --spinner dot --title "Generating fish completions..." -- fish -c fish_update_completions
    log_message $ERROR "Failed to create fish completion files."
    exit 1
end
log_message $INFO "Generated fish completions."
