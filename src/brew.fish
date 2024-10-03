#!/opt/homebrew/bin/fish
# brew.fish - Homebrew initialization and configuration

function validate_installation
    # ensure installation
    if not command -q brew
        gum log -l error "Homebrew is not installed or not in PATH"
        return 1
    end

    # ensure prefix is set
    set -l brew_prefix (brew --prefix)
    if test -z "$brew_prefix"
        gum log -l error "Failed to determine Homebrew prefix"
        return 1
    end
    gum log -l info "Determined brew prefix: "(gum style -th code $brew_prefix)

    # ensure homebrew health
    if not gum spin --show-output --title "Checking homebrew health..." -- brew doctor | format_output
        gum log -l warn "Homebrew doctor reported issues."
        if not gum confirm "Continue with homebrew setup?"
            return 1
        end
    else
        gum log -l info "Homebrew is healthy!"
    end

    return 0
end

function install_bundle
    set -l bundle_file (cfg '.brew.bundle_file')

    # fallback to default if not specified
    if test -z "$bundle_file" -o ! -f "$bundle_file"
        set bundle_file "$HOME/.Brewfile"
        gum log -l info "Bundle path not specified in config, using fallback: "(gum style -th code $bundle_file)
    end

    # set global env var
    if test -f "$bundle_file"
        set -Ux HOMEBREW_BUNDLE_FILE_GLOBAL $bundle_file
        gum log -l info "Using brewfile: "(gum style -th code $HOMEBREW_BUNDLE_FILE_GLOBAL)
    else
        gum log -l error "No valid Brewfile found. Please put one at: "(gum style -th code $HOME/.Brewfile)
        return 1
    end

    # install bundle
    if test (cfg '.brew.cleanup') = true
        # if cleanup mode is enabled
        if gum confirm "Warning: This will uninstall all Brew packages and only re-install from "(gum style -th code $HOMEBREW_BUNDLE_FILE_GLOBAL)
            gum log -l info "Uninstalling all brew packages and only re-installing from: "(gum style -th code $HOMEBREW_BUNDLE_FILE_GLOBAL)
            if not gum spin --show-output --title "Uninstalling packages..." -- brew bundle --force cleanup --global | format_output
                gum log -l error "Errors were produced while uninstalling Brew packages"
            end
        else
            gum log -l info "Cleanup cancelled by user"
        end
    else
        # if cleanup mode is disabled (default)
        gum log -l info "Installing packages from Brewfile: "(gum style -th code $HOMEBREW_BUNDLE_FILE_GLOBAL)
        if not gum spin --show-output --title "Installing packages..." -- brew bundle --global | format_output
            gum log -l error "Errors were produced while installing Brew packages from: "(gum style -th code $HOMEBREW_BUNDLE_FILE_GLOBAL)
        end
    end
end

function update
    gum log -l info "Updating Homebrew..."
    if not gum spin --show-output --title "Updating Homebrew..." -- brew update | format_output
        gum log -l error "Failed to update Homebrew"
        return 1
    end

    gum log -l info "Upgrading formulae and casks..."
    if not gum spin --show-output --title "Upgrading formulae and casks..." -- brew upgrade | format_output
        gum log -l warn "Some formulae or casks failed to upgrade"
    end

    if command -q mas
        gum log -l info "Upgrading App Store apps..."
        if not gum spin --show-output --title "Upgrading App Store apps..." -- mas upgrade | format_output
            gum log -l warn "Some App Store apps failed to upgrade using "(gum style -th code "mas upgrade")
        end
    else
        gum log -l warn "mas not installed. Skipping App Store updates."
    end

    return 0
end

function configure_autoupdate
    if test (cfg '.brew.autoupdate') = true
        if test (cfg '.brew.autoupdate_interval') -gt 0
            gum log -l info "Configuring Homebrew auto-update..."

            # Attempt to delete existing configuration
            if not command brew autoupdate delete >/dev/null 2>&1
                gum log -l warn "Failed to delete existing auto-update configuration. Attempting to force delete."
                if not command brew autoupdate delete --force >/dev/null 2>&1
                    gum log -l error "Failed to force delete existing auto-update configuration. Aborting."
                    return 1
                end
            end
            gum log -l debug "Existing auto-update configuration deleted successfully"

            set -l interval (math (cfg '.brew.autoupdate_interval'))

            if not command brew autoupdate start $interval --upgrade --cleanup --immediate --sudo >/dev/null 2>&1
                gum log -l error "Failed to set up Homebrew auto-update"
                return 1
            end
            set -l formatted_interval (gum style -th code "$interval")
            gum log -l info "Homebrew packages will now be updated every $formatted_interval seconds."
        else
            set -l formatted_config_value (gum style -th code (cfg '.brew.autoupdate_interval'))
            gum log -l error "$formatted_config_value is not set or is not greater than "(gum style -th code "0")
            return 1
        end
    else
        gum log -l info "Disabling Homebrew auto-update"
        if command brew autoupdate delete >/dev/null 2>&1
            gum log -l info "Homebrew auto-update disabled successfully"
        else
            gum log -l debug "No auto-update configuration to disable"
        end
    end
    return 0
end

function main
    gum log -l debug "Starting Homebrew configuration..."

    if not validate_installation
        gum log -l error "Failed to validate Homebrew configuration."
        return 1
    end

    if not install_bundle
        gum log -l error "Failed to install Brewfile"
        return 1
    end

    if not update
        gum log -l error "Failed to update Homebrew and packages"
        return 1
    end

    if not configure_autoupdate
        gum log -l error "Failed to configure Homebrew auto-update"
        return 1
    end
end

if not main $argv
    gum log -l error "Homebrew configuration failed. Aborting."
    exit 1
end
