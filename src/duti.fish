#!/opt/homebrew/bin/fish
# duti.fish - Set default applications for file types

function verify_duti
    if not command -q duti
        gum log -l error "The 'duti' command is not installed."
        gum log -l info "Installing duti with Homebrew..."

        if not brew install duti
            gum log -l error "Failed to install duti. Aborting."
            return 1
        end

        gum log -l info "Successfully installed duti."
    else
        gum log -l debug "duti is already installed."
    end

    return 0
end

function set_file_associations
    set -l app_id "com.todesktop.230313mzl4w4u92"
    set -l total_count 0
    set -l success_count 0

    gum log -l info "Setting file associations for $app_id..."

    # UTI associations
    set -l utis \
        "public.json" \
        "public.plain-text" \
        "public.python-script" \
        "public.shell-script" \
        "public.source-code" \
        "public.text" \
        "public.unix-executable" \
        "public.data"

    # File extension associations
    set -l extensions \
        ".c" ".cpp" ".cs" ".css" ".go" ".java" ".js" \
        ".sass" ".scss" ".less" ".vue" ".cfg" ".json" \
        ".jsx" ".log" ".lua" ".md" ".php" ".pl" ".py" \
        ".rb" ".ts" ".tsx" ".txt" ".conf" ".yaml" ".yml" ".toml"

    # Set UTI associations
    for uti in $utis
        set total_count (math $total_count + 1)
        set -l formatted_uti (gum style -th code "$uti")

        if duti -s $app_id $uti all 2>/dev/null
            set success_count (math $success_count + 1)
            gum log -l debug "Set $formatted_uti to open with $app_id"
        else
            gum log -l warn "Failed to set $formatted_uti to open with $app_id"
        end
    end

    # Set file extension associations
    for ext in $extensions
        set total_count (math $total_count + 1)
        set -l formatted_ext (gum style -th code "$ext")

        if duti -s $app_id $ext all 2>/dev/null
            set success_count (math $success_count + 1)
            gum log -l debug "Set $formatted_ext to open with $app_id"
        else
            gum log -l warn "Failed to set $formatted_ext to open with $app_id"
        end
    end

    # Report results
    gum log -l info "Set $success_count out of $total_count file associations."

    if test $success_count -eq $total_count
        return 0
    else
        return 1
    end
end

function main
    gum log -l debug "Starting file association configuration..."

    if not verify_duti
        gum log -l error "Failed to ensure duti is installed."
        return 1
    end

    if not set_file_associations
        gum log -l warn "Some file associations could not be set."

        if not gum confirm "Continue despite file association failures?"
            gum log -l error "Aborted by user after file association failures."
            return 1
        end
    else
        gum log -l info "All file associations set successfully."
    end

    return 0
end

if not main $argv
    gum log -l error "File association configuration failed."
    exit 1
end
