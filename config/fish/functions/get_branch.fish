function get_branch -d "Detect various Git branch names"
    set -lx GUM_FORMAT_THEME "$__fish_themes_dir/tui.json"
    set -lx GLAMOUR_STYLE "$__fish_themes_dir/tui.json"

    set -l subcommand $argv[1]
    set -lx valid_subcommands
    set -lx subcommand_descriptions

    set -l subcommands active dev feature-prepend main
    set -l descriptions \
        "Get the current active branch" \
        "Get the development branch name" \
        "Get the feature branch prefix" \
        "Get the main branch name"

    for i in (seq (count $subcommands))
        set -a valid_subcommands $subcommands[$i]
        set -a subcommand_descriptions "$subcommands[$i]:$descriptions[$i]"
    end

    function _help
        set -l help \
            "# Usage: _gitbranch_ `<command>`" \
            "## Various helper functions for getting the properties of Git branches" \
            "# Commands:" \
            "- **active**                   Get the current active branch" \
            "- **dev**                      Get the development branch name" \
            "- **feature-prepend**          Get the feature branch prefix" \
            "- **main**                     Get the main branch name" \
            "# Flags:" \
            "- **--help**                   Show help for subcommand"

        gum format -- $help
    end

    function _gitbranch_active
        set -l current_branch (git branch --show-current)
        if test -n "$current_branch"
            echo $current_branch
        else
            gum log -l error "No active branch found"
            return 1
        end
    end

    function _gitbranch_dev
        for branch in dev devel development
            if command git show-ref -q --verify refs/heads/$branch
                echo $branch
                return 0
            end
        end
        gum log -l error "No development branch found"
        return 1
    end

    function _gitbranch_feature_prepend
        set -l feat_branch (string match -q '*/feat/*' (git show-ref))
        if test $status -eq 0
            echo feat
        else
            set -l feature_branch (string match -q '*/feature/*' (git show-ref))
            if test $status -eq 0
                echo feature
            else
                gum log -l error "No feature branch pattern found"
                return 1
            end
        end
    end

    function _gitbranch_main
        for ref in refs/{heads,remotes/{origin,upstream}}/{main,master,trunk}
            if command git show-ref -q --verify $ref
                echo (string split -r -m1 -f2 / $ref)
                return 0
            end
        end
        gum log -l error "No main branch found"
        return 1
    end

    if test (count $argv) -eq 0
        _help
        return 1
    end

    if contains -- --help $argv
        _help
        return 0
    end

    if not contains -- $subcommand $valid_subcommands
        gum log --structured --level error "Invalid subcommand: $subcommand"
        _help
        return 1
    end

    if not command git rev-parse --git-dir &>/dev/null
        gum log --structured --level error "Not a git repository"
        return 1
    end

    switch $subcommand
        case active
            _gitbranch_active
        case dev
            _gitbranch_dev
        case feature-prepend
            _gitbranch_feature_prepend
        case main
            _gitbranch_main
        case '*'
            _gitbranch_main
    end
end
