#!/opt/homebrew/bin/fish
# op.fish
# Sets up 1Password CLI + SSH agent

function main
    # ensure 1password is signed in
    if not gum spin --title "Prompting for 1Password login..." -- op signin | format_output
        gum log -l error "Failed to sign in to 1Password. Aborting."
        return 1
    else
        gum log -l info "Successfully signed in to 1Password."
    end

    # github plugin
    if gum confirm "Setup 1Password GitHub plugin?"
        if op plugin init gh | format_output
            gum log -l info "Successfully initialized 1Password GitHub plugin."
        else
            gum log -l error "Failed to initialize 1Password GitHub plugin."
        end
    end

    # homebrew plugin
    if gum confirm "Setup 1Password homebrew plugin?"
        if op plugin init brew | format_output
            gum log -l info "Successfully initialized 1Password homebrew plugin."
        else
            gum log -l error "Failed to initialize 1Password homebrew plugin."
        end
    end

    # ssh agent
    set -l launch_agents_dir "$HOME/Library/LaunchAgents" && mkdir -p $launch_agents_dir
    set -l plist_file "$launch_agents_dir/com.1password.SSH_AUTH_SOCK.plist"

    # create the plist file with $HOME expanded
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
        gum log -l error "Error loading LaunchAgent: "(gum style -th code $load_output)
        set -l bootstrap_output (sudo launchctl bootstrap system $plist_file 2>&1)
        set -l bootstrap_status $status

        if test $bootstrap_status -eq 0
            gum log -l info "Successfully bootstrapped LaunchAgent as root."
        else
            gum log -l error "Error bootstrapping LaunchAgent: "(gum style -th code $bootstrap_output)
            return 1
        end
    else
        gum log -l info "1Password SSH agent is setup."
    end

    # verify SSH_AUTH_SOCK
    if test -S "$SSH_AUTH_SOCK"
        gum log -l info "SSH_AUTH_SOCK is properly set and points to a valid socket."
    else
        gum log -l warn "Warning: SSH_AUTH_SOCK is not set or does not point to a valid socket: "(gum style -th code $SSH_AUTH_SOCK)
    end
end

main $argv
