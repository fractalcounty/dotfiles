function __gum_spin
    ## options
    set -gx GUM_SPIN_SHOW_OUTPUT false # show or pipe output of command during execution
    set -gx GUM_SPIN_SHOW_ERROR true # show output of command only if the command fails
    set -gx GUM_SPIN_SPINNER points # line, dot, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger

    ## style flags
    set -gx GUM_SPIN_SPINNER_FOREGROUND $theme_blue
    set -e GUM_SPIN_SPINNER_BACKGROUND
    set -gx GUM_SPIN_TITLE_FOREGROUND $theme_normal
    set -e GUM_SPIN_TITLE_BACKGROUND
end
