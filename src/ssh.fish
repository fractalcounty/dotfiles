#!/opt/homebrew/bin/fish
# ssh.fish
# Sets up 1Password + SSH agent

function format_output
    echo
    gum style --border none --foreground "$TEXT" --background "$INACTIVE_BG" $argv
    echo
end

function main
    if not gum spin --title "Prompting for 1Password login..." -- op signin
        log_message $ERROR "Failed to sign in to 1Password. Aborting."
        return 1
    else
        log_message $INFO "Successfully signed in to 1Password."
        if not op plugin init brew
            log_message $ERROR "Failed to initialize 1Password plugin. Aborting."
            return 1
        else
            log_message $INFO "Successfully initialized 1Password plugin."

            if not op plugin inspect brew
                log_message $ERROR "Failed to inspect 1Password plugin. Aborting."
                return 1
            else
                log_message $INFO "Successfully inspected 1Password plugin."
            end
        end
    end

    set -l launch_agents_dir "$HOME/Library/LaunchAgents"
    set -l plist_file "$launch_agents_dir/com.1password.SSH_AUTH_SOCK.plist"

    # Create LaunchAgents directory if it doesn't exist
    if not test -d $launch_agents_dir
        mkdir -p $launch_agents_dir
    end

    # Create the plist file with $HOME expanded
    echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.1password.SSH_AUTH_SOCK</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>/bin/ln -sf '$HOME'/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock $SSH_AUTH_SOCK</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>' >$plist_file

    # Load the LaunchAgent
    set -l load_output (launchctl load -w $plist_file 2>&1)
    set -l load_status $status

    if test $load_status -ne 0
        log_message $ERROR "Error loading LaunchAgent: $load_output"
        log_message $INFO "Attempting to bootstrap as root..."
        set -l bootstrap_output (sudo launchctl bootstrap system $plist_file 2>&1)
        set -l bootstrap_status $status

        if test $bootstrap_status -eq 0
            log_message $INFO "Successfully bootstrapped LaunchAgent as root."
        else
            log_message $ERROR "Error bootstrapping LaunchAgent: $bootstrap_output. Please check your system configuration and try again"
            return 1
        end
    else
        log_message $INFO "1Password SSH agent is setup."
    end

    # Verify SSH_AUTH_SOCK
    if test -S "$SSH_AUTH_SOCK"
        log_message $INFO "SSH_AUTH_SOCK is properly set and points to a valid socket."
    else
        log_message $WARNING "Warning: SSH_AUTH_SOCK is not set or does not point to a valid socket."
        log_message $WARNING "Current SSH_AUTH_SOCK value: $SSH_AUTH_SOCK"
    end
end

main $argv
