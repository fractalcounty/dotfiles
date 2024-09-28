# __brew.fish - Homebrew initialization

## env vars
set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_DEVELOPER 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx BUN_INSTALL "$HOMEBREW_PREFIX/opt/bun/bin"

# keg-only apps
set -l keg_only_apps ruby curl sqlite rustup bun

for app in $keg_only_apps
    mkdir -p "$HOMEBREW_PREFIX/opt/$app/bin"
    fish_add_path -gPm "$HOMEBREW_PREFIX/opt/$app/bin"
    set MANPATH "$HOMEBREW_PREFIX/opt/$app/share/man" $MANPATH
end

# add homebrew binaries to front of path
fish_add_path -gPm "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"

# homebrew completions
if test -e "$HOMEBREW_PREFIX/share/fish/completions"
    set -a fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
end
