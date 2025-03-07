## gnu coreutils
fish_add_path -m "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"

## bun
set -gx BUN_INSTALL "$XDG_DATA_HOME/bun"; and mkdir -p "$BUN_INSTALL/bin/"
fish_add_path "$BUN_INSTALL/bin"

## uv 
uv generate-shell-completion fish | source
uvx --generate-shell-completion fish | source
source "$HOME/.local/share/../bin/env.fish"
set -gx UV_CACHE_DIR "$XDG_CACHE_HOME/uv"; and mkdir -p "$UV_CACHE_DIR"

# ## deno
# set -gx DENO_INSTALL_ROOT $XDG_DATA_HOME/deno/bin; and mkdir -p $DENO_INSTALL_ROOT
# set -gx DENO_REPL_HISTORY "$XDG_STATE_HOME/deno_history.txt"
# set -gx DENO_DIR $XDG_CACHE_HOME/deno; and mkdir -p $DENO_DIR
# fish_add_path "$DENO_INSTALL_ROOT"

## homebrew
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_DEVELOPER 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx HOMEBREW_BUNDLE_NO_LOCK 1
set -gx HOMEBREW_PREFIX /opt/homebrew
fish_add_path -m "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"

if test -e "$HOMEBREW_PREFIX/share/fish/completions"
    set -a fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
end

for manpath in (path filter $__fish_data_dir/man /usr/local/share/man /usr/share/man "$HOMEBREW_PREFIX/share/man")
    set -a MANPATH $manpath
end

for infopath in (path filter $__fish_data_dir/info /usr/local/share/info /usr/share/info "$HOMEBREW_PREFIX/share/info")
    set -a INFOPATH $infopath
end
