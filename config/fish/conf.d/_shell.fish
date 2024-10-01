#
# _shell.fish - fish + fisher initialization
#

set -gx __fish_config_dir $HOME/.config/fish
set -gx __fish_cache_dir $XDG_CACHE_HOME/fish
set -gx __fish_plugins_dir $__fish_config_dir/plugins
set -gx __fish_themes_dir $__fish_config_dir/themes
set -gx fisher_path $__fish_config_dir/plugins

mkdir -p $__fish_config_dir $__fish_cache_dir $__fish_plugins_dir $__fish_themes_dir

if test "$fisher_paths_initialized" != true
    set --local idx (contains -i $__fish_config_dir/functions $fish_function_path || echo 1)
    set fish_function_path $fish_function_path[1..$idx] $fisher_path/functions $fish_function_path[(math $idx + 1)..]

    set --local idx (contains -i $__fish_config_dir/completions $fish_complete_path || echo 1)
    set fish_complete_path $fish_complete_path[1..$idx] $fisher_path/completions $fish_complete_path[(math $idx + 1)..]

    set -g fisher_paths_initialized true
end

if not test -d $fisher_path
    functions -e fisher &>/dev/null
    mkdir -p $fisher_path
    touch $__fish_config_dir/fish_plugins
    curl -sL https://git.io/fisher | source
    if test -s $__fish_config_dir/fish_plugins
        fisher update
    else
        fisher install jorgebucaran/fisher
    end
end

for file in $fisher_path/conf.d/*.fish
    if ! test -f $__fish_config_dir/conf.d/(path basename -- $file)
        and test -f $file && test -r $file
        builtin source $file
    end
end

# allow subdirs for functions and completions.
set fish_function_path (path resolve $__fish_config_dir/functions/*/) $fish_function_path
set fish_complete_path (path resolve $__fish_config_dir/completions/*/) $fish_complete_path
## add .hushlogin to disable login greeting if it doesn't exist already
if not test -f $HOME/.hushlogin
    touch $HOME/.hushlogin
end

## disable new user greeting
set fish_greeting

# atuin
set -gx COLORTERM truecolor
atuin init fish | source

## initialize starship prompt
set -Ux STARSHIP_CONFIG $__fish_config_dir/themes/starship.toml
type -q starship || return 1
cachecmd starship init fish | source
enable_transience

## man page paths
for manpath in (path filter $__fish_data_dir/man /usr/local/share/man /usr/share/man)
    set -a MANPATH $manpath
end
