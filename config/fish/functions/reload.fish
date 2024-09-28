function reload --description 'Refresh terminal while preserving the current directory'
    set -l current_dir (pwd)

    if not test -d "$current_dir"
        echo "Error: Current directory no longer exists." >&2
        return 1
    end

    switch "$TERM_PROGRAM"
        case WezTerm
            if not command -q wezterm
                echo "Error: WezTerm CLI not found." >&2
                return 1
            end

            if not wezterm cli spawn --cwd "$current_dir"
                echo "Error: Failed to spawn new WezTerm tab." >&2
                return 1
            end

            wezterm cli kill-pane

        case WarpTerminal
            if not command -q open
                echo "Error: 'open' command not found." >&2
                return 1
            end

            if not open -a Warp.app "$current_dir"
                echo "Error: Failed to open new Warp window." >&2
                return 1
            end

            exit 0

        case '*'
            echo "Error: Unsupported terminal: $TERM_PROGRAM" >&2
            return 1
    end
end
