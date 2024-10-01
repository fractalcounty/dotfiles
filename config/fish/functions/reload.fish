function reload --description 'Refresh terminal while preserving the current directory'
    set -l current_dir (pwd)

    if not test -d "$current_dir"
        echo "Error: Current directory no longer exists." >&2
        return 1
    end

    switch "$TERM_PROGRAM"
        case ghostty
            if not command -q open
                echo "Error: 'open' command not found." >&2
                return 1
            end

            if not open -a Ghostty.app "$current_dir"
                echo "Error: Failed to open new ghostty window." >&2
                return 1
            end

            sleep 0.5

            exit 0

        case '*'
            echo "Error: Unsupported terminal: $TERM_PROGRAM" >&2
            return 1
    end
end
