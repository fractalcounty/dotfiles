function reload --description 'Refresh terminal while preserving the current directory'
    set -l current_dir (pwd)

    set -l app_name "$TERM_PROGRAM.app"
    if not open -a $app_name "$current_dir"
        gum log -l error "Failed to open new "(gum style -th code "$TERM_PROGRAM")" window."
        return 1
    end

    sleep 0.5

    exit 0
end
