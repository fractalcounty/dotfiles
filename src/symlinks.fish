#!/opt/homebrew/bin/fish
# symlinks.fish - Environment setup script
# Creates symlinks and sets up dotfiles repo

function main
    # ensure $REPO_DIR is set
    if not set -q REPO_DIR
        gum log -l error "REPO_DIR is not set. Please set it manually or run this through "(gum style -th code fish.fish.)
        return 1
    end

    # Fetch symlinks from $CONFIG file
    set -l symlinks (cfg '.symlinks | to_entries | .[] | [.key, .value] | .[]')

    gum log -l info "The following symlinks will be created:"
    echo

    set counter 1
    for i in (seq 1 2 (count $symlinks))
        set -l src (eval echo $symlinks[$i])
        set -l dest (eval echo $symlinks[(math $i + 1)])
        set -l src_formatted (gum style -th code "$src")
        set -l dest_formatted (gum style -th code "$dest")
        echo "$counter. $src_formatted"
        echo "   ↳ $dest_formatted"
        echo
        set counter (math $counter + 1)
    end
    echo

    if gum confirm "Do you want to proceed?"
        gum log -l debug "Creating symlinks and setting permissions..."

        for i in (seq 1 2 (count $symlinks))
            set -l src (eval echo $symlinks[$i])
            set -l dest (eval echo $symlinks[(math $i + 1)])

            # remove existing symlinks or files at destination
            if test -e $dest -o -L $dest
                gum log -l debug "Removing existing file or symlink: $dest"
                rm -rf $dest
            end

            # Create the symlink
            if test -d $src
                ln -s $src $dest # file symlink
            else
                ln -s $src $dest # dir symlink
            end
            gum log -l debug "Created symlink: $dest"
        end

        gum log -l debug "Environment setup completed"
    else
        return 1
    end
end

main $argv
