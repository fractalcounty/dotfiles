#!/opt/homebrew/bin/fish
# Main entrypoint setup script
# Runs selected scripts in ./src/

set -gx REPO_DIR (realpath (dirname (status -f)))
set -x CONFIG "$REPO_DIR/config.yaml"
set -q GUM_THEMES_DIR; or set -gx GUM_THEMES_DIR "$REPO_DIR/config/fish/themes/gum"

set setup_scripts \
    "system.fish:💻:System settings successfully set!" \
    "symlinks.fish:🔗:Symlinks created successfully!" \
    "brew.fish:🍺:Homebrew is properly configured!" \
    "fish.fish:🐟:Fish shell is properly configured!" \
    "op.fish:🔑: 1Password CLI and SSH is good to go!" \
    "finish.fish:✨:Setup is complete!"

source "$REPO_DIR/config/fish/functions/alias/gum.fish"
source "$REPO_DIR/config/fish/functions/slog.fish"

function cfg
    yq $argv $CONFIG
end

if test (cfg '.verbose') = true
    slog debug
else
    slog info
end

function format_output
    while read -l line
        gum style -th output "$line"
    end
end

function run_all_scripts
    for script_entry in $setup_scripts
        set parts (string split ":" $script_entry)
        set script $parts[1]
        set emoji $parts[2]
        set outro $parts[3]
        if not run_script "$script" "$emoji" "$outro"
            return 1
        end
    end
end

function run_script
    set script $argv[1]
    set emoji $argv[2]
    set outro $argv[3]
    set script_path "$REPO_DIR/src/$script"

    if not test -f "$script_path"
        gum log -l error "$script not found in $REPO_DIR/src/"
        return 1
    end

    chmod +x "$script_path"
    if test "$script" != "finish.fish"
        gum style -th section "$emoji $script"
    end

    source "$script_path"

    set exit_status $status

    if test $exit_status -ne 0
        gum log -l error "$emoji $script exited with non-zero status."
        if not gum confirm "Do you want to continue with the setup?"
            gum log -l error "Setup aborted by user."
            exit 1
        end
    else
        gum log -l info "$outro"
        # example: ✨ Setup is complete!
    end
end

function run_selected_scripts
    for script in $argv
        set emoji "🔧"
        set outro "Script completed!"
        for script_entry in $setup_scripts
            set parts (string split ":" $script_entry)
            if test $parts[1] = $script
                set emoji $parts[2]
                set outro $parts[3]
                break
            end
        end
        if not run_script "$script" "$emoji" "$outro"
            return 1
        end
    end
end

function main
    gum style "chip's macOS dotfiles" -th="title"

    set run_option (gum choose --header="Commands:" "Run (auto)" "Run (custom)" "System update" "Open in IDE")

    switch "$run_option"
        case 'Run (auto)'
            if gum confirm "Are you sure you want to run all scripts automatically?"
                gum log -l info "Starting automatic setup..."
                run_all_scripts
                echo
            else
                gum log -l warn "Automatic setup cancelled."
            end
            exit $status
        case 'Run (custom)'
            set script_names
            for script in $setup_scripts
                set parts (string split ":" $script)
                set -a script_names $parts[1]
            end
            set selected_scripts (gum choose --no-limit --header "Select setup scripts:" $script_names)

            if test (count $selected_scripts) -eq 0
                gum log -l warn "No scripts selected. Exiting."
                exit 0
            end

            run_selected_scripts $selected_scripts
            exit $status
        case 'System update'
            update
            exit $status
        case 'Open in IDE'
            ide $REPO_DIR
            exit $status
    end
end

for arg in $argv
    switch $arg
        case --verbose
            set -gx VERBOSE true
    end
end

main $argv
