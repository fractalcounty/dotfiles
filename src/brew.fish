#!/opt/homebrew/bin/fish
# brew.fish - Homebrew initialization and configuration

function format_output
    echo
    gum style --border none --foreground "$TEXT" --background "$INACTIVE_BG"
    echo
end

function run_and_format
    set -l cmd $argv
    set -l output (eval $cmd 2>&1)
    set -l cmd_status $status
    if test -n "$output"
        echo "$output" | format_output
    end
    return $cmd_status
end

function validate_installation
    if not command -q brew
        log_message $ERROR "Homebrew is not installed or not in PATH"
        return 1
    end

    set -l brew_prefix (brew --prefix)
    if test -z "$brew_prefix"
        log_message $ERROR "Failed to determine Homebrew prefix"
        return 1
    end
    set -l formatted_brew_prefix (gum style --foreground "$TEXT" --background "$INACTIVE_BG" "$brew_prefix")
    log_message $INFO "Determined brew prefix: $formatted_brew_prefix"

    log_message $INFO "Checking homebrew health..."
    if not run_and_format "brew doctor"
        log_message $WARNING "Homebrew doctor reported issues"
    else
        log_message $INFO "Homebrew is healthy!"
    end

    return 0
end

function install_bundle
    set -l bundle_file (cfg '.brew.bundle_file')
    set -l default_brewfile $HOME/.Brewfile

    if test -z "$bundle_file" -o ! -f "$bundle_file"
        set bundle_file $default_brewfile
        log_message $INFO "bundlefile not specified in config.yaml. Using default: "(format_code $bundle_file)
    end

    if test -f "$bundle_file"
        set -Ux HOMEBREW_BUNDLE_FILE_GLOBAL $bundle_file
        log_message $INFO "Using brewfile: "(format_code $HOMEBREW_BUNDLE_FILE_GLOBAL)
    else
        log_message $ERROR "No valid Brewfile found. Please create one at: "(format_code $default_brewfile)
        return 1
    end

    if test (cfg '.brew.cleanup') = true
        if gum confirm "Warning: This will uninstall all Brew packages and only re-install from "(format_code $HOMEBREW_BUNDLE_FILE_GLOBAL)" Continue?"
            log_message $INFO "Uninstalling all brew packages and only re-installing from: "(format_code $HOMEBREW_BUNDLE_FILE_GLOBAL)""
            if not run_and_format "brew bundle --force cleanup --global"
                log_message $ERROR "Failed to cleanup and reinstall Brew packages"
                return 1
            end
        else
            log_message $INFO "Cleanup cancelled by user"
        end
    else
        log_message $INFO "Installing packages from Brewfile: "(format_code $HOMEBREW_BUNDLE_FILE_GLOBAL)""
        if not brew bundle --global | format_output
            log_message $ERROR "Failed to install packages from "(format_code $HOMEBREW_BUNDLE_FILE_GLOBAL)""
            return 1
        end
    end
end

function update
    log_message $INFO "Updating Homebrew..."
    if not run_and_format "brew update"
        log_message $ERROR "Failed to update Homebrew"
        return 1
    end

    log_message $INFO "Upgrading formulae and casks..."
    if not run_and_format "brew upgrade"
        log_message $WARNING "Some formulae or casks failed to upgrade"
    end

    if command -q mas
        log_message $INFO "Upgrading App Store apps..."
        if not run_and_format "mas upgrade"
            log_message $WARNING "Some App Store apps failed to upgrade"
        end
    else
        log_message $WARNING "mas not installed. Skipping App Store updates."
    end

    return 0
end

function configure_autoupdate
    if test (cfg '.brew.autoupdate') = true
        if test (cfg '.brew.autoupdate_interval') -gt 0
            log_message $INFO "Configuring Homebrew auto-update..."

            # Attempt to delete existing configuration
            if not command brew autoupdate delete >/dev/null 2>&1
                log_message $WARN "Failed to delete existing auto-update configuration. Attempting to force delete."
                if not command brew autoupdate delete --force >/dev/null 2>&1
                    log_message $ERROR "Failed to force delete existing auto-update configuration. Aborting."
                    return 1
                end
            end
            log_message $DEBUG "Existing auto-update configuration deleted successfully"

            set -l interval (math (cfg '.brew.autoupdate_interval'))

            if not command brew autoupdate start $interval --upgrade --cleanup --immediate --sudo >/dev/null 2>&1
                log_message $ERROR "Failed to set up Homebrew auto-update"
                return 1
            end
            set -l formatted_interval (gum style --foreground "$TEXT" --background "$INACTIVE_BG" "$interval")
            log_message $INFO "Homebrew packages will now be updated every $formatted_interval seconds."
        else
            log_message $ERROR "brew.autoupdate_interval is not set or is not greater than 0"
            return 1
        end
    else
        log_message $INFO "Disabling Homebrew auto-update"
        if command brew autoupdate delete >/dev/null 2>&1
            log_message $INFO "Homebrew auto-update disabled successfully"
        else
            log_message $DEBUG "No auto-update configuration to disable"
        end
    end
    return 0
end

function main
    log_message $DEBUG "Starting Homebrew configuration..."

    if not validate_installation
        log_message $ERROR "Failed to validate Homebrew configuration."
        return 1
    end

    if not install_bundle
        log_message $ERROR "Failed to install Brewfile"
        return 1
    end

    if not update
        log_message $ERROR "Failed to update Homebrew and packages"
        return 1
    end

    if not configure_autoupdate
        log_message $ERROR "Failed to configure Homebrew auto-update"
        return 1
    end
end

if not main $argv
    log_message $ERROR "Homebrew configuration failed. Aborting."
    exit 1
end
