function slog --description 'Set LOG_LEVEL to a valid value'
    set -l valid_levels debug info warn error fatal

    if test (count $argv) -ne 1
        echo "Usage: slog <level>"
        echo "Valid levels: $valid_levels"
        return 1
    end

    if not contains -- $argv[1] $valid_levels
        echo "Error: Invalid log level '$argv[1]'"
        echo "Valid levels: $valid_levels"
        return 1
    end

    set -gx LOG_LEVEL $argv[1]
    if test $LOG_LEVEL = debug
        echo "Log level set to $LOG_LEVEL"
    end
end
