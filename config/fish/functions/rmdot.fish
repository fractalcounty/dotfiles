function rmdot --description 'Safely delete non-important metadata files recursively'
    set -l dry_run false
    set -l target_dir $PWD

    function print_help
        echo "Usage: rmdot [OPTIONS] [DIRECTORY]"
        echo
        echo "Safely delete non-important metadata files recursively from a given directory."
        echo
        echo "Options:"
        echo "  -h, --help    Show this help message"
        echo "  -d, --dry     Perform a dry run without deleting files"
        echo
        echo "If no directory is specified, the current directory will be used."
    end

    # Parse arguments
    set -l options h/help d/dry
    argparse -n rmdot $options -- $argv
    or return

    if set -q _flag_help
        print_help
        return 0
    end

    if set -q _flag_dry
        set dry_run true
    end

    if test (count $argv) -gt 0
        set target_dir $argv[1]
    end

    # Validate target directory
    if not test -d $target_dir
        gum style --foreground "$theme_red" "Error: '$target_dir' is not a valid directory."
        return 1
    end

    # Define metadata files to be removed
    set -l metadata_patterns '.DS_Store' '._.DS_Store'

    # Elevate to sudo if not a dry run
    if test $dry_run = false
        if not sudo -v
            gum style --foreground "$theme_red" "Error: Failed to elevate sudo privileges."
            return 1
        end
    end

    # Use fd to find metadata files efficiently
    set -l files_to_remove (sudo fd -H -I -t f (string join '|' $metadata_patterns) $target_dir)

    if test (count $files_to_remove) -eq 0
        gum style --foreground "$theme_orange" "No metadata files found in '$target_dir'."
        return 0
    end

    # Group files by name and count occurrences
    set -l grouped_files (string replace -r '.*/(.*)' '$1' $files_to_remove | sort | uniq -c | sort -rn)

    # Display grouped files
    echo "Files to be removed:"
    for line in $grouped_files
        set -l count (string match -r '^\s*(\d+)' $line)[2]
        set -l file (string replace -r '^\s*\d+\s+' '' $line)
        gum style --foreground "$theme_blue" "  $file: $count occurrences"
    end

    echo

    # Confirm action
    if test $dry_run = false
        if not gum confirm "Do you want to proceed with deletion?"
            gum style --foreground "$theme_orange" "Operation cancelled."
            return 0
        end
    end

    # Perform deletion or dry run
    set -l total_files (count $files_to_remove)
    set -l removed_files 0

    if test $dry_run = true
        gum style --foreground "$theme_blue" "Dry run: Would remove the following files:"
        for file in $files_to_remove
            gum style --foreground "$theme_light_gray" "• $file"
            set removed_files (math $removed_files + 1)
        end
    else
        # Use a single sudo call for all deletions
        echo $files_to_remove | sudo xargs rm -f
        set removed_files (count $files_to_remove)
    end

    # Final summary
    if test $dry_run = true
        gum style --foreground "$theme_blue" "Dry run complete. $total_files files would be removed."
    else
        gum style --foreground "$theme_blue" "Operation complete. Attempted to remove $removed_files out of $total_files files."
    end
end
