#!/opt/homebrew/bin/fish
# system.fish

gum log -l debug "Attempting to close System Preferences..."
osascript -e 'tell application "System Preferences" to quit'

function format_output
    while read -l line
        gum style -th output "$line"
    end
end

# Keep-alive: update existing `sudo` time stamp until script has finished
gum log -l debug "Setting up sudo keep-alive..."
fish -c "while true; sudo -n true; sleep 60; kill -0 $fish_pid || exit; end" &

function set_system_value
    set -l key $argv[1]
    set -l value $argv[2]
    set -l formatted_key (gum style -th code $key)

    gum log -l debug "Attempting to set $formatted_key to "(gum style -th code $value)

    if test $key = NetBIOSName
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$value"
    else
        sudo scutil --set $key "$value"
    end

    if test $status -eq 0
        gum log -l info "Set $formatted_key to "(gum style -th code $value)
        return 0
    else
        gum log -l error "Failed to set $formatted_key to "(gum style -th code $value)
        return 1
    end
end

function create_netbios_name
    set -l host_name $argv[1]
    echo $host_name | tr '[:lower:]' '[:upper:]' | tr -cd '[:alnum:]' | string sub -l 15
end

function set_system_values
    set -l friendly_name (cfg '.system.friendly_name')
    set -l host_name (cfg '.system.host_name')

    if test -z "$friendly_name" -o -z "$host_name"
        gum log -l error "Missing friendly_name or host_name in configuration. Aborting."
        return 1
    end

    # Ask for sudo password upfront and add a newline
    sudo -v

    set -l netbios_name (create_netbios_name $host_name)

    set_system_value ComputerName $friendly_name
    and set_system_value HostName $host_name
    and set_system_value LocalHostName $host_name
    and set_system_value NetBIOSName $netbios_name

    if test $status -eq 0
        gum log -l debug "All system names set successfully."
        return 0
    else
        gum log -l error "Failed to set one or more system names."
        return 1
    end
end

function set_macos_defaults
    set -l macos_path "$REPO_DIR/macos.yaml"

    if not test -e "$macos_path"
        gum log -l error "MacOS config directory does not exist: "(gum style -th code $macos_path)
        return 1
    else
        gum log -l info "Applying macOS defaults from: "(gum style -th code $macos_path)
    end

    set -l output (macos-defaults apply "$macos_path" 2>&1 | format_output)
    if test $status -ne 0
        gum log -l error "Failed to apply macOS defaults from "(gum style -th code macos.yaml)
        echo $output
        return 1
    end

    echo $output

    gum log -l debug "Successfully applied macOS defaults."
    return 0
end

function main
    gum log -l debug "Starting system configuration..."
    if set_system_values
        gum log -l debug "System names set successfully."
        set_macos_defaults
        gum log -l debug "System configuration completed successfully."
    else
        gum log -l error "System configuration failed."
        return 1
    end
end

if not main $argv
    gum log -l error "Script execution failed."
    exit 1
end
