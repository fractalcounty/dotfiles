function colors --description 'Preview 16 and 256 colors your terminal'
    set -l TEXT gYw
    set -l TEXT_COL (set_color normal)
    set -l RESET (set_color normal)

    printf "\n%sYour terminal supports %s colors.\n" $TEXT_COL (tput colors)

    printf "\n%s16-Bit Palette%s\n\n" $TEXT_COL $RESET
    set -l base_colors 40m 41m 42m 43m 44m 45m 46m 47m
    for BG in $base_colors
        printf " \e[%bm       \e[0m" $BG
    end
    echo

    for BG in $base_colors
        printf " \e[1;30m\e[%b  %b   \e[0m" $BG $BG
    end
    echo

    for BG in $base_colors
        printf " \e[%bm       \e[0m" $BG
    end
    echo

    printf "\n                 40m     41m     42m     43m\
     44m     45m     46m     47m\n"

    set -l FGs '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
        '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
        '  36m' '1;36m' '  37m' '1;37m'

    for FGs in $FGs
        set -l FG (string replace -a ' ' '' -- $FGs)
        printf " %s \e[%sm  %s  " $FGs $FG $TEXT
        for BG in $base_colors
            printf " \e[%s\e[%s  %s  \e[0m" $FG $BG $TEXT
        end
        echo
    end

    printf "\n%s256-Bit Palette%s\n\n" $TEXT_COL $RESET
    for i in (seq 0 255)
        printf '\e[38;5;%dm%3d ' $i $i
        test (math "($i + 3) % 18") = 0; and printf '\e[0m\n'
    end
    echo
end
