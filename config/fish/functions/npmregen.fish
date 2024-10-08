function npmregen --description "Regenerate Node-derived project dependencies and build files"
    set -l options (fish_opt --short=h --long=help)
    set -a options (fish_opt --short=f --long=force)
    argparse $options -- $argv

    if set -q _flag_help
        echo "Usage: npmregen [options]"
        echo
        echo "Regenerate Node-derived project dependencies and build files."
        echo
        echo "Options:"
        echo "  -h, --help   Show this help message"
        echo "  -f, --force  Skip confirmation prompt"
        return 0
    end

    # Ensure we're in a Node.js project root
    if not test -f package.json
        gum log -l error "Not in a Node.js project root. No package.json found."
        return 1
    end

    set -l package_manager (pmdetect)
    set -l targets node_modules/ .astro/ dist/ build/ $package_manager.lock

    set -l existing_targets
    for target in $targets
        if test -e $target
            set -a existing_targets $target
        end
    end

    if test (count $existing_targets) -eq 0
        gum log -l warn "No targets found to regenerate."
        return 0
    end

    gum style -th prompt "The following paths will be regenerated:"

    for target in $existing_targets
        echo (gum format -- "- `$target`")
    end
    echo

    if not set -q _flag_force
        if not gum confirm "Remove and regenerate?"
            gum log -l warn "Operation cancelled."
            return 1
        end
    end

    for target in $existing_targets
        if test -d $target
            gum spin --title "Removing "(gum style -th code "$target") -- rm -rf "$target"
        else
            gum spin --title "Removing "(gum style -th code "$target") -- rm -f "$target"
        end
    end

    switch $package_manager
        case yarn
            gum spin --title "Reinstalling dependencies..." -- yarn install
        case pnpm
            gum spin --title "Reinstalling dependencies..." -- pnpm install
        case bun
            gum spin --title "Reinstalling dependencies..." -- bun install
        case npm
            gum spin --title "Reinstalling dependencies..." -- npm install
    end

    if contains .astro/ $existing_targets
        gum spin --title "Syncing Astro..." -- $package_manager run astro sync
    end

    gum log -l info "Regeneration complete."
    gum log -l info "You may want to run your build or static generate commands now."
end
