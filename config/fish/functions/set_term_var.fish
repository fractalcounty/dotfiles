# upstream: https://github.com/mattmc3/fishconf/blob/f05877bd7244f4c8fda5c63b87879e9f2457e358/functions/set_term_var.fish#L1
#
# This function emits an OSC 1337 sequence to set a user var
# associated with the current terminal pane.
# It requires the `base64` utility to be available in the path.

function set_term_var
    if hash base64 2>/dev/null
        if test -z "$TMUX"
            printf "\033]1337;SetUserVar=%s=%s\007" $argv[1] (echo -n $argv[2] | base64)
        else
            # <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
            # Note that you ALSO need to add "set -g allow-passthrough on" to your tmux.conf
            printf "\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\" $argv[1] (echo -n $argv[2] | base64)
        end
    end
end
