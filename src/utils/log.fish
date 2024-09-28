#!/opt/homebrew/bin/fish
# Logging for setup.fish

set -gx DEBUG 0
set -gx INFO 1
set -gx WARNING 2
set -gx ERROR 3
set -gx LOG_LEVEL $INFO
set -gx LOG_OK "✅"

function log_message
    set level $argv[1]
    set message $argv[2]
    set label
    set color

    switch $level
        case $DEBUG
            set label "[DEBUG]"
            set color $INACTIVE_FG
        case $INFO
            set label ""
            set color $TEXT
        case $WARNING
            set label "[WARNING]"
            set color $ORANGE
        case $ERROR
            set label "[ERROR]"
            set color $RED
        case '*'
            echo "Invalid log level" >&2
            return 1
    end

    # Show DEBUG only if VERBOSE is true, always show INFO, WARNING, and ERROR
    if test $level -ge $INFO; or test $level -eq $DEBUG -a "$VERBOSE" = "true"
        gum style --foreground "$color" "$label $message"
    end
end

function set_verbose_mode
    set -gx VERBOSE true
    log_message $DEBUG "Verbose mode enabled"
end

if test "$VERBOSE" = "true"
    set_verbose_mode
end