#
# _shell.fish - fish + fisher initialization
#

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

## initialize starship prompt
set -Ux STARSHIP_CONFIG $__fish_config_dir/themes/starship.toml
type -q starship || return 1
cachecmd starship init fish | source
enable_transience

fzf_configure_bindings --directory=\cf --history=""
set -gxa FZF_DEFAULT_OPTS "--color=fg:-1,fg+:#bb9af7,bg:-1,bg+:#373d5a --color=hl:#7dcfff,hl+:#bb9af7,info:#565f89,marker:#73daca --color=prompt:#2ac3de,spinner:#2ac3de,pointer:#bb9af7,header:#565f89 --color=border:#373d5a,label:#7dcfff,query:#7aa2f7"

set -gx fifc_editor "$EDITOR"
set -gx fifc_bat_opts --color=always --wrap=character

slog info

if status is-interactive
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
    atuin init fish | source
end
