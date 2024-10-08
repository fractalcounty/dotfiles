# xdg base directories
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state
set -gx XDG_CACHE_HOME $HOME/.cache
mkdir -p $XDG_CONFIG_HOME $XDG_DATA_HOME $XDG_STATE_HOME $XDG_CACHE_HOME

# custom dirs
set -gx PROJECTS $HOME/Projects
set -gx DOTFILES $PROJECTS/dotfiles
mkdir -p $PROJECTS $DOTFILES

# fish
set -gx __fish_config_dir $HOME/.config/fish
set -gx __fish_cache_dir $XDG_CACHE_HOME/fish
set -gx __fish_themes_dir $__fish_config_dir/themes
set -gx fisher_path $__fish_config_dir/plugins
mkdir -p $__fish_config_dir $__fish_cache_dir $__fish_plugins_dir $__fish_themes_dir $fisher_path

# editors
set -gx PAGER less
set -gx VISUAL cursor
set -gx EDITOR micro
set -gx BROWSER open

# ensure manpage is set
set -q MANPATH; or set -gx MANPATH ''
set -q INFOPATH; or set -gx INFOPATH ''

# xdg apps
set -gx CURL_HOME $XDG_CONFIG_HOME/curl; and mkdir -p $CURL_HOME
set -gx GNUPGHOME $XDG_DATA_HOME/gnupg; and mkdir -p $GNUPGHOME
set -gx SQLITE_HISTORY $XDG_DATA_HOME/sqlite_history; and mkdir -p $SQLITE_HISTORY
set -gx LESSHISTFILE $XDG_DATA_HOME/lesshst
set -gx _ZO_DATA_DIR $XDG_DATA_HOME; and mkdir -p $_ZO_DATA_DIR
set -gx DOCKER_CONFIG $XDG_CONFIG_HOME/docker; and mkdir -p $DOCKER_CONFIG

# misc options
set -gx GIT_PAGER delta
set -gx BAT_PAGER 'less -R'
set -gx MICRO_TRUECOLOR 1
set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
