# $HOME/.config/fish/functions/gum.fish

function gum --wraps gum --description 'Wrapper for gum providing additional theme functionality'

    function _help
        set -lx GUM_FORMAT_THEME "$__fish_themes_dir/tui.json"
        set -lx GLAMOUR_STYLE "$__fish_themes_dir/tui.json"

        set -l help \
            "# chip's gum wrapper script" \
            "## Various additions to the gum CLI tool" \
            "# Commands:" \
            "- **gum log**   -l \<level\> \<message\>       Publish a log message" \
            "- **slog**         \<level\>                 Set the global log level safely" \
            "# Environment:" \
            "- **GUM_THEMES_DIR**                       Directory containing custom theme files"
        gum format -- $help
    end

    if contains -- --help $argv; or contains -- -h $argv
        command gum $argv
        _help
        return 0
    end

    # GUM_THEMES_DIR must be set to activate wrapper
    if set -q GUM_THEMES_DIR && test -d $GUM_THEMES_DIR
        set -l subcommand $argv[1]
        set -l theme
        set -l new_argv

        # parse arguments to find --theme or -th
        set -l i 1
        while test $i -le (count $argv)
            set -l arg $argv[$i]
            switch $arg
                case '--theme=*'
                    set theme (string split -m 1 '=' -- $arg)[2]
                case '-th=*'
                    set theme (string split -m 1 '=' -- $arg)[2]
                case --theme -th
                    set -q argv[(math $i + 1)] && set theme $argv[(math $i + 1)]
                    set i (math $i + 1)
                case --wrapper -wr
                    gum log -l info --prefix="Gum Wrapper" "Active!"
                    return 0
                case '*'
                    set -a new_argv $arg
            end
            set i (math $i + 1)
        end

        # src the subcommand-specific theme file if it exists
        set -l subcommand_theme_file $GUM_THEMES_DIR/$subcommand.fish
        if test -f $subcommand_theme_file
            source $subcommand_theme_file
        else
            gum log -l warn --prefix="Gum Wrapper" "'$subcommand_theme_file' is invalid or missing."
        end

        # apply the subcommand's default theme if it exists
        set -l default_theme "__gum_$subcommand"
        if functions -q $default_theme
            $default_theme
        else
            gum log -l warn --prefix="Gum Wrapper" "Default theme function '$default_theme' is invalid or missing from '$subcommand_theme_file'."
        end

        # apply custom theme if specified
        if test -n "$theme"
            set -l custom_theme "__gum_"$subcommand"_$theme"
            if functions -q $custom_theme
                $custom_theme
            else
                gum log -l warn --prefix="Gum Wrapper" "Custom theme function '$custom_theme' is invalid or missing from '$subcommand_theme_file'."
            end
        end

        if test "$subcommand" = log
            set -l message_level none

            for index in (seq 2 (count $argv))
                set -l arg $argv[$index]
                switch $arg
                    case '--level=*'
                        set message_level (string split -m 1 '=' -- $arg)[2]
                    case --level
                        set -l next_index (math $index + 1)
                        if set -q argv[$next_index]
                            set message_level $argv[$next_index]
                        end
                    case '-l=*'
                        set message_level (string split -m 1 '=' -- $arg)[2]
                    case -l
                        set -l next_index (math $index + 1)
                        if set -q argv[$next_index]
                            set message_level $argv[$next_index]
                        end
                end
            end

            if test "$message_level" = warn
                set message_level warning
            end

            switch $message_level
                case debug
                    if set -q GUM_LOG_LEVEL_DEBUG
                        set -gx GUM_LOG_LEVEL_FOREGROUND $GUM_LOG_LEVEL_DEBUG
                    else
                        # Fallback to default color if custom variable is not set
                        set -gx GUM_LOG_LEVEL_FOREGROUND $theme_dark_gray
                    end
                case info
                    if set -q GUM_LOG_LEVEL_INFO
                        set -gx GUM_LOG_LEVEL_FOREGROUND $GUM_LOG_LEVEL_INFO
                    else
                        set -gx GUM_LOG_LEVEL_FOREGROUND $theme_foreground
                    end
                case warning
                    if set -q GUM_LOG_LEVEL_WARNING
                        set -gx GUM_LOG_LEVEL_FOREGROUND $GUM_LOG_LEVEL_WARNING
                    else
                        set -gx GUM_LOG_LEVEL_FOREGROUND $theme_orange
                    end
                case error
                    if set -q GUM_LOG_LEVEL_ERROR
                        set -gx GUM_LOG_LEVEL_FOREGROUND $GUM_LOG_LEVEL_ERROR
                    else
                        set -gx GUM_LOG_LEVEL_FOREGROUND $theme_red
                    end
                case fatal
                    if set -q GUM_LOG_LEVEL_FATAL
                        set -gx GUM_LOG_LEVEL_FOREGROUND $GUM_LOG_LEVEL_FATAL
                    else
                        set -gx GUM_LOG_LEVEL_FOREGROUND $theme_red
                    end
                case none
                    # No specific color for 'none' level
                    set -gx GUM_LOG_LEVEL_FOREGROUND ''
                case '*'
                    # Unknown levels default to no color
                    set -gx GUM_LOG_LEVEL_FOREGROUND ''
            end

            set -l message_level_num 0
            switch $message_level
                case debug
                    set message_level_num 1
                case info
                    set message_level_num 2
                case warning
                    set message_level_num 3
                case error
                    set message_level_num 4
                case fatal
                    set message_level_num 5
                case none
                    set message_level_num 0
                case '*'
                    set message_level_num 0
            end

            # map global LOG_LEVEL to numeric value
            set -l log_level_num 0
            switch $LOG_LEVEL
                case debug
                    set log_level_num 1
                case info
                    set log_level_num 2
                case warning
                    set log_level_num 3
                case error
                    set log_level_num 4
                case fatal
                    set log_level_num 5
                case '*'
                    set log_level_num 0
            end

            # determine whether to display the log message
            if test "$message_level_num" -ge "$log_level_num" -o "$message_level" = none
                # proceed to execute the gum log command
                command gum $new_argv
            else
                # Do not display the log message; exit silently
                return 0
            end
        else
            # for all other subcommands, proceed as usual
            command gum $new_argv
        end
    else
        # If GUM_THEMES_DIR is not set or not a valid directory, pass through to original gum command
        command gum $argv
    end
end
