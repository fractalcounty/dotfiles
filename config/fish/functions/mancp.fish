function mancp --description 'Copy manpage to clipboard or file with preserved formatting'
    argparse h/help 'o/output=' -- $argv
    or return

    if set -q _flag_help
        echo "Usage: mancp [OPTIONS] COMMAND"
        echo "Options:"
        echo "  -h, --help           Show this help message"
        echo "  -o, --output FILE    Output to file instead of clipboard"
        return 0
    end

    if test (count $argv) -eq 0
        gum style --foreground "$RED" "Error: No command specified"
        return 1
    end

    set -l command $argv[1]

    # Check if the command exists and has a man page
    if not man -w $command &>/dev/null
        gum style --foreground "$RED" "Error: No manpage found for '$command'"
        return 1
    end

    # Set MANWIDTH to terminal width or 80 if not available
    set -l term_width (tput cols)
    set -l man_width (test -n "$term_width"; and echo $term_width; or echo 80)

    # Capture man page output with proper width and remove problematic characters
    set -l formatted_manpage (env MANWIDTH=$man_width man $command | col -bx | sed 's/.\x08//g')

    if set -q _flag_output
        set -l output_file $_flag_output
        set -l output_dir (dirname $output_file)

        # Check if the directory exists, create it if it doesn't
        if not test -d $output_dir
            mkdir -p $output_dir
        end

        echo $formatted_manpage >$output_file
        if test $status -eq 0
            gum style --foreground "$GREEN" "Manpage for '$command' saved to $output_file"
        else
            gum style --foreground "$RED" "Error: Unable to save manpage to $output_file"
            return 1
        end
    else
        echo -n $formatted_manpage | pbcopy
        gum style --foreground "$GREEN" "Manpage for '$command' copied to clipboard"
    end
end
