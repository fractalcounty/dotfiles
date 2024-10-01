#
# env - system-wide env variables
#

# xdg base directories
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_BIN_HOME $HOME/.local/bin
mkdir -p $XDG_CONFIG_HOME $XDG_DATA_HOME $XDG_STATE_HOME $XDG_CACHE_HOME

# custom dirs
set -gx PROJECTS $HOME/Projects
set -gx DOTFILES $PROJECTS/dotfiles
mkdir -p $PROJECTS $DOTFILES

# editors
set -gx PAGER less
set -gx VISUAL cursor
set -gx EDITOR micro
set -gx BROWSER open

# manpages
set -q MANPATH; or set -gx MANPATH ''

# initial working directory
set -g IWD $PWD

# xdg apps
set -gx GNUPGHOME $XDG_DATA_HOME/gnupg
set -gx LESSHISTFILE $XDG_DATA_HOME/lesshst
set -gx SQLITE_HISTORY $XDG_DATA_HOME/sqlite_history
set -gx _ZO_DATA_DIR $XDG_DATA_HOME
set -gx DOCKER_CONFIG $XDG_CONFIG_HOME/docker
set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
set -gx GIT_PAGER delta
set -gx BAT_PAGER 'less -R'
set -gx MICRO_TRUECOLOR 1
