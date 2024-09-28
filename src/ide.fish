#!/opt/homebrew/bin/fish
# ide.fish - visual ide configuration script

function set_current_ide
    set -Ux VISUAL (cfg '.ide') # Allowed Values: code, code-insiders, cursor, zed
    log_message $DEBUG "Set primary visual IDE to: "(format_code $VISUAL)
end

function main
    if set_current_ide
        log_message $DEBUG "Visual IDE configured successfully."
    else
        log_message $ERROR "Visual IDE configuration failed."
        return 1
    end
end

if not main $argv
    log_message $ERROR "Script execution failed."
    exit 1
end
