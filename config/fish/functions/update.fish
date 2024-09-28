function update --description 'Updates everything!'

    # Define update commands
    set -l update_commands \
        "brew:Updating Homebrew:brew update" \
        "brew:Upgrading Homebrew packages:brew upgrade" \
        "mas:Upgrading App Store apps:mas upgrade" \
        "fish:Upgrading fisher plugins:fisher update" \
        "rustup:Upgrading Rust:rustup update" \
        "rustup:Upgrading Cargo packages:cargo update --workspace"

    # Function to run update command
    function run_update_command
        set -l cmd $argv[1]
        set -l title $argv[2]
        set -l command $argv[3]

        if begin
                test "$cmd" = fish; or command -sq $cmd
            end
            gum spin --show-output --title (gum style --foreground "$BLUE" "$title") -- fish -c "$command"
            set -l cmd_status $status
            if test $cmd_status -ne 0
                gum style --foreground "$RED" "Failed to $title (Exit code: $cmd_status)"
                return 1
            else
                gum style --foreground "$GREEN" "$title completed successfully"
            end
        else
            gum style --foreground "$ORANGE" "Skipping $title - $cmd not found."
            return 1
        end
    end

    # Run update commands
    set -l success_count 0
    set -l total_commands (count $update_commands)

    for update in $update_commands
        set -l parts (string split ":" $update)
        if run_update_command $parts
            set success_count (math $success_count + 1)
        end
    end

    if test $success_count -eq $total_commands
        gum style --foreground "$GREEN" "All updates completed successfully!"
    else
        set -l failed_count (math $total_commands - $success_count)
        gum style --foreground "$ORANGE" "$failed_count out of $total_commands updates encountered issues. Check the output above for details."
    end

    # Check if Rust toolchain is installed
    if not command -sq rustc
        gum style --foreground "$ORANGE" "Rust toolchain not found. To install, run: 'rustup default stable'"
    end
end
