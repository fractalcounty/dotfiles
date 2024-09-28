#!/opt/homebrew/bin/fish
# system.fish

# Close any open System Preferences panes
log_message $DEBUG "Attempting to close System Preferences..."
osascript -e 'tell application "System Preferences" to quit'

function sudo_with_newline
    sudo -v
    echo # This adds a newline after the password prompt
end

function format_output
    while read -l line
        echo (gum style --border none --foreground "$TEXT" --background "$INACTIVE_BG" "$line")
    end
end


# Keep-alive: update existing `sudo` time stamp until script has finished
log_message $DEBUG "Setting up sudo keep-alive..."
fish -c "while true; sudo -n true; sleep 60; kill -0 $fish_pid || exit; end" &

function set_system_value
    set -l key $argv[1]
    set -l value $argv[2]
    set -l formatted_key (gum style --foreground "$TEXT" --background "$INACTIVE_BG" $key)
    set -l formatted_value (gum style --foreground "$TEXT" --background "$INACTIVE_BG" $value)

    log_message $DEBUG "Attempting to set $formatted_key to $formatted_value"

    if test $key = NetBIOSName
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$value"
    else
        sudo scutil --set $key "$value"
    end

    if test $status -eq 0
        log_message $INFO "Set $formatted_key to $formatted_value"
        return 0
    else
        log_message $ERROR "Failed to set $formatted_key to $formatted_value"
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
        log_message $ERROR "Missing friendly_name or host_name in configuration. Aborting."
        return 1
    end

    gum style --foreground="$PURPLE" --padding "1 0" "Configuring system name:"

    # Ask for sudo password upfront and add a newline
    sudo_with_newline

    set -l netbios_name (create_netbios_name $host_name)

    set_system_value ComputerName $friendly_name
    and set_system_value HostName $host_name
    and set_system_value LocalHostName $host_name
    and set_system_value NetBIOSName $netbios_name

    if test $status -eq 0
        log_message $DEBUG "All system names set successfully."
        return 0
    else
        log_message $ERROR "Failed to set one or more system names."
        return 1
    end
end

function set_macos_defaults
    set -l macos_path "$REPO_DIR/macos.yaml"

    if not test -e "$macos_path"
        log_message $ERROR "MacOS config directory does not exist: "(format_code $macos_path)
        return 1
    else
        log_message $INFO "Applying macOS defaults from: "(format_code $macos_path)
    end

    set -l output (macos-defaults apply "$macos_path" 2>&1 | format_output)
    if test $status -ne 0
        log_message $ERROR "Failed to apply macOS defaults from macos.yaml"
        echo $output
        return 1
    end

    echo
    echo $output
    echo

    log_message $DEBUG "Successfully applied macOS defaults."
    return 0
end


function main
    log_message $DEBUG "Starting system configuration..."
    if set_system_values
        log_message $DEBUG "System names set successfully."
        set_macos_defaults
        log_message $DEBUG "System configuration completed successfully."
    else
        log_message $ERROR "System configuration failed."
        return 1
    end
end

if not main $argv
    log_message $ERROR "Script execution failed."
    exit 1
end
