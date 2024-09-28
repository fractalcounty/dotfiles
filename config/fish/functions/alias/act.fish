function act --description "act wrapper with 1Password authentication via -op flag" --wraps act
    set -l args
    set -l use_token false

    for arg in $argv
        if test "$arg" = -op
            set use_token true
        else
            set -a args $arg
        end
    end

    if test "$use_token" = true
        command act $args -s GITHUB_TOKEN="$(op read 'op://Development/GitHub Classic PAT/token')"
    else
        command act $args
    end
end
