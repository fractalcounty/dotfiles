#!/opt/homebrew/bin/fish
# symlinks.fish - Environment setup script
# Creates symlinks and sets up dotfiles repo

function main
    #log_message $DEBUG "Starting symlinks setup..."

    # Ensure $REPO_DIR is set
    if not set -q REPO_DIR
        #log_message $ERROR "REPO_DIR is not set. Please run this script through setup.fish"
        return 1
    end

    # Fetch symlinks from $CONFIG file
    set -l symlinks (cfg '.symlinks | to_entries | .[] | [.key, .value] | .[]')

    #log_message $INFO "The following symlinks will be created:"
    echo

    set counter 1
    for i in (seq 1 2 (count $symlinks))
        set -l src (eval echo $symlinks[$i])
        set -l dest (eval echo $symlinks[(math $i + 1)])
        set -l src_formatted (gum style --foreground "$TEXT" --background "$INACTIVE_BG" "$src")
        set -l dest_formatted (gum style --foreground "$TEXT" --background "$INACTIVE_BG" "$dest")
        echo "$counter. $src_formatted"
        echo "   ↳ $dest_formatted"
        echo
        set counter (math $counter + 1)
    end
    echo

    if gum confirm "Do you want to proceed?"
        #log_message $DEBUG "Creating symlinks and setting permissions..."

        for i in (seq 1 2 (count $symlinks))
            set -l src (eval echo $symlinks[$i])
            set -l dest (eval echo $symlinks[(math $i + 1)])

            # Remove existing symlinks or files at destination
            if test -e $dest -o -L $dest
                #log_message $DEBUG "Removing existing file or symlink: $dest"
                rm -rf $dest
            end

            # Create the symlink
            #log_message $DEBUG "Creating symlink: $src -> $dest"
            if test -d $src
                # Create directory symlink
                ln -s $src $dest
            else
                # Create file symlink
                ln -s $src $dest
            end
            #log_message $DEBUG "Created symlink: $dest"
        end

        #log_message $DEBUG "Environment setup completed"
    else
        #log_message $WARNING "Setup cancelled by user"
        return 1
    end
end

main $argv
