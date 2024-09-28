# upstream: https://github.com/mattmc3/fishconf/blob/main/functions/ide.fish

function ide --description 'Use $VISUAL to open a project directory'
    set -l dir (string match -r '.' $argv '.')[1]
    set -q VISUAL || set -gx VISUAL vim
    $VISUAL $dir
end
