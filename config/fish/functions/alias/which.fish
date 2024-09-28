function which --description 'Enhanced which command with simple inline formatting' --wraps which
    argparse h/help -- $argv
    or return

    if set -q _flag_help
        echo "Usage: which [OPTIONS] COMMAND..."
        echo "Options:"
        echo "  -h, --help    Show this help message"
        return 0
    end

    if test (count $argv) -eq 0
        echo "Error: No command specified"
        return 1
    end

    for cmd in $argv
        set -l found false
        set -l output

        # abbreviation
        if abbr --query $cmd
            set found true
            set -a output (gum style --foreground "$PURPLE" "Abbreviation: ")(gum style --foreground "$TEXT" (abbr --show | string match -r ".*$cmd.*"))
        end

        # function
        if functions -q $cmd
            set found true
            set -a output (gum style --foreground "$PURPLE" "Function:")
            set -a output (gum style --foreground "$TEXT" (functions $cmd | string collect))
        end

        # alias
        if test (alias | string match -r "^alias $cmd\\s" | count) -gt 0
            set found true
            set -a output (gum style --foreground "$PURPLE" "Alias: ")(gum style --foreground "$TEXT" (alias | string match -r "^alias $cmd\\s"))
        end

        # external commands
        set -l external_cmd (command -v $cmd)
        if test -n "$external_cmd"
            set found true
            set -a output (gum style --foreground "$PURPLE" "External command: ")(gum style --foreground "$TEXT" "$external_cmd")

            # executable
            if test -x "$external_cmd"
                set -a output (gum style --foreground "$PURPLE" "Type: ")(gum style --foreground "$TEXT" (file -b "$external_cmd"))
            end

            # version information
            if command -sq $cmd
                set -l version_info ($cmd --version 2>/dev/null | string collect | string replace -r '\n.*' '')
                if test -n "$version_info"
                    set -a output (gum style --foreground "$PURPLE" "Version: ")(gum style --foreground "$TEXT" "$version_info")
                end
            end
        end

        if test $found = false
            set output (gum style --foreground "$RED" "Not found: $cmd")
        end

        # results
        gum style --border none --margin "0 0" --padding "0 1" $output
    end
end
