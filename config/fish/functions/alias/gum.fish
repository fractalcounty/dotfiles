function gum --wraps gum --description 'Wrapper for gum CLI with style preset support'
    # Source the gum styles file if it exists
    if test -f $GUM_STYLE_FILE
        source $GUM_STYLE_FILE
    else
        gum style --foreground="$theme_orange" "Warning: gum styles file not found, gum wrapper will be disabled."
    end

    set -l subcommand $argv[1]
    set -l style
    set -l new_argv

    # Parse arguments to find --style or -s
    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        switch $arg
            case '--style=*'
                set style (string split -m 1 '=' -- $arg)[2]
            case '-s=*'
                set style (string split -m 1 '=' -- $arg)[2]
            case --style -s
                set -q argv[(math $i + 1)] && set style $argv[(math $i + 1)]
                set i (math $i + 1)
            case --test -t
                gum style --foreground="$theme_green" "Gum wrapper function is active!"
                return 0
            case '*'
                set -a new_argv $arg
        end
        set i (math $i + 1)
    end

    # Apply default style for the subcommand if it exists
    set -l default_style "__gum_$subcommand"
    if functions -q $default_style
        $default_style
    end

    # Apply custom style if specified
    if test -n "$style"
        set -l custom_style "__gum_"$subcommand"_$style"
        if functions -q $custom_style
            $custom_style
        else
            gum style --foreground="$theme_orange" "Warning: Custom style '$style' for '$subcommand' not found. Using default style only."
        end
    end

    # Execute gum with the processed arguments
    command gum $new_argv
end
