#!/opt/homebrew/bin/fish
# fish.fish - fish shell configuration script

gum log -l debug "Starting initialization process..."

gum log -l debug "Ensuring fish is in "(gum style -th code /etc/shells)
if not grep -q /opt/homebrew/bin/fish /etc/shells
    echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells >/dev/null
    if test $status -ne 0
        gum log -l error "Failed to add fish to "(gum style -th code /etc/shells)
        exit 1
    end
    gum log -l info "Added fish to "(gum style -th code /etc/shells)
else
    gum log -l info "Fish is in "(gum style -th code /etc/shells)
end

gum log -l debug "Ensuring fish is the default shell..."
if not string match -q "*fish" $SHELL
    if not sudo chsh -s /opt/homebrew/bin/fish $USER
        gum log -l error "Failed to set fish as the default shell."
        exit 1
    end
    gum log -l info "Fish shell has been set as the default shell."
else
    gum log -l info "Fish is the default shell."
end

gum log -l debug "Ensuring homebrew's binaries are in the fish path..."
if not contains /opt/homebrew/bin $fish_user_paths
    fish_add_path /opt/homebrew/bin
    if test $status -ne 0
        gum log -l error "Failed to add Homebrew's binaries to fish "(gum style -th code PATH)
        exit 1
    end
    gum log -l info "Homebrew's binaries have been added to fish "(gum style -th code PATH)
else
    gum log -l debug "Homebrew's binaries are in the fish "(gum style -th code PATH)
end

gum log -l debug "Attempting to create fish completion files..."
if not gum spin --title "Generating fish completions..." -- fish -c fish_update_completions
    gum log -l error "Failed to create fish completion files."
    exit 1
end
gum log -l info "Generated fish completions."
