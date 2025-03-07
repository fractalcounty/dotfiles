# Do not erase these comments, they are here for LLM context!
# Terraria executable path: '$HOME/Library/Application Support/Steam/steamapps/common/Terraria/Terraria.app'
# Terraria.bin.osx path: '$HOME/Library/Application Support/Steam/steamapps/common/Terraria/Terraria.app/Contents/MacOS/Terraria.bin.osx'
# Terraria user data path (i.e saves, player data, etc.): '$HOME/Library/Application Support/Terraria'

# global script constants
set -g TERRARIA_APP "$HOME/Library/Application Support/Steam/steamapps/common/Terraria/Terraria.app"
set -g BIN_PATH "$TERRARIA_APP/Contents/MacOS/Terraria.bin.osx"
set -g TERRARIA_ARM_RELEASE "1.0.1"
set -g TERRARIA_ARM_URL "https://github.com/Candygoblen123/TerrariaArmMac/releases/download/$TERRARIA_ARM_RELEASE/Terraria.Arm.zip"
set -g TERRARIA_ARM_MARKER "$TERRARIA_APP/.arm_native"

# global environment variables for native Terraria execution
set -gx DYLD_LIBRARY_PATH "$TERRARIA_APP/Contents/MacOS/osx"
set -gx DYLD_FRAMEWORK_PATH /System/Library/Frameworks
set -gx SDL_VIDEODRIVER metal
set -gx SDL_METAL_FORCE_DIRECT 1
set -gx MONO_IMAGE_ABI ARM64
set -gx SDL_VIDEO_MAC_FULLSCREEN_SPACES 0
set -gx MONO_FORCE_NATIVE 1
set -gx MONO_GAC_PREFIX "$TERRARIA_APP/Contents/Resources"
set -gx MONO_CONFIG "$TERRARIA_APP/Contents/MonoConfig"
set -gx MONO_PATH "$TERRARIA_APP/Contents/Resources"

function __install_terraria_arm -a force
    # if force flag is set, skip all checks and proceed with install
    if test "$force" = --force
        set -l testvar true
    else
        # check for native files only if not forcing
        set -l has_native_files true
        for path in $required_paths
            set -l target_path (string replace "Terraria Arm/" "" "$path")
            if not test -f "$TERRARIA_APP/$target_path"
                set has_native_files false
                break
            end
        end

        if test "$has_native_files" = true
            gum log -l info "Native ARM files already installed"
            return 0
        else if not gum confirm "Native ARM files not found. Would you like to install them?"
            gum log -l error "Native ARM files are required to run Terraria natively"
            return 1
        end
    end

    set -l tmp_dir (mktemp -d)
    pushd $tmp_dir || return 1

    # download and extract
    gum log -l info "Downloading Terraria ARM files..."
    curl -L "$TERRARIA_ARM_URL" -o terraria_arm.zip --progress-bar || begin
        gum log -l error "Failed to download Terraria ARM files"
        popd
        rm -rf $tmp_dir
        return 1
    end

    unzip -q terraria_arm.zip || begin
        gum log -l error "Failed to extract Terraria ARM files"
        popd
        rm -rf $tmp_dir
        return 1
    end

    # verify files
    for path in $required_paths
        if not test -f "$tmp_dir/$path"
            gum log -l error "Missing required file: $path"
            popd
            rm -rf $tmp_dir
            return 1
        end
    end

    # backup original files
    set -l backup_dir "$TERRARIA_APP/backup_"(date +%Y%m%d_%H%M%S)
    gum spin --show-output --title="Backing up original files..." -- "
        mkdir -p '$backup_dir'
        for path in $required_paths
            set -l target_path (string replace 'Terraria Arm/' '' '$path')
            set -l dir (dirname '$backup_dir/$target_path')
            mkdir -p '$dir'
            if test -f '$TERRARIA_APP/$target_path'
                cp -p '$TERRARIA_APP/$target_path' '$backup_dir/$target_path'
            end
        end
    "

    # install new files
    gum spin --show-output --title="Installing ARM native files..." -- "
        for path in $required_paths
            set -l target_path (string replace 'Terraria Arm/' '' '$path')
            set -l dir (dirname '$TERRARIA_APP/$target_path')
            mkdir -p '$dir'
            cp -p '$tmp_dir/$path' '$TERRARIA_APP/$target_path'
        end
    "

    gum style --foreground "#9ece6a" "✓ Successfully installed Terraria ARM native files"

    popd
    rm -rf $tmp_dir
end

function terraria

    clear
    slog info

    # set info log level
    set -gx GUM_LOG_LEVEL info

    argparse f/force -- $argv

    # Pass the actual flag to the install function
    if not __install_terraria_arm "$_flag_force"
        gum log -l error "Failed to install ARM files"
        return 1
    end

    # check if terraria is already running
    if set -l existing_pid (pgrep -i "terraria|tmodloader")
        gum log -l error "Terraria is already running with PID $existing_pid"
        return 1
    end

    # create monoconfig file to ensure native libraries are used
    if not test -f "$TERRARIA_APP/Contents/MonoConfig"
        echo '<configuration>
      <dllmap dll="i:cygwin1.dll" target="libc.dylib"/>
      <dllmap dll="libc" target="libc.dylib"/>
      <dllmap dll="intl" target="libintl.dylib"/>
      <dllmap dll="libintl" target="libintl.dylib"/>
      <dllmap dll="i:libxslt.dll" target="libxslt.dylib"/>
      <dllmap dll="i:odbc32.dll" target="libodbc.dylib"/>
      <dllmap dll="i:wxbase28u_net_vc_custom.dll" target="libwx_macu_net-2.8.dylib"/>
      <dllmap dll="SDL2" target="libSDL2-2.0.0.dylib"/>
      <dllmap dll="FNA3D" target="libFNA3D.0.dylib"/>
      <dllmap dll="FAudio" target="libFAudio.0.dylib"/>
      <dllmap dll="SDL2_image" target="libSDL2_image-2.0.0.dylib"/>
      <dllmap dll="theorafile" target="libtheorafile.dylib"/>
  </configuration>' | sudo tee "$TERRARIA_APP/Contents/MonoConfig" >/dev/null
    end

    # run terraria
    gum log -l info "Launching Terraria at steam://rungameid/105600"
    open "steam://rungameid/105600"

    # wait for terraria to start with gum spinner (with 30s timeout)
    if not gum spin --timeout 30s --title="Waiting for Terraria to start..." --show-output -- fish -c '
        while true
            # look for both the .app process and the binary
            set -l pid (pgrep -f "Terraria\.app|Terraria\.bin\.osx")
            if test -n "$pid"
                echo $pid > /tmp/terraria_pid
                exit 0
            end
            sleep 0.5
        end
    '
        gum log -l error "Timed out waiting for Terraria to start"
        return 1
    end

    set -l pid (cat /tmp/terraria_pid)
    rm -f /tmp/terraria_pid

    # setup cleanup handler for ctrl+c
    function __cleanup_terraria --on-signal INT --inherit-variable pid
        gum log -l info "Cleaning up Terraria process..."
        # kill both the .app and the binary
        pkill -f "Terraria\.app|Terraria\.bin\.osx"
        # wait for processes to exit
        while pgrep -f "Terraria\.app|Terraria\.bin\.osx" >/dev/null
            sleep 0.1
        end
        functions -e __cleanup_terraria
        exit 0
    end

    gum log -l debug "Terraria started with PID $pid"

    # add delay to let terraria fully initialize
    gum spin --spinner dot --title="Letting Terraria initialize..." --timeout 10s -- sleep 10

    gum log -l info "Terraria fully initialized with PID $pid"

    # get process details using lsof instead of pwdx (which isn't available on macOS)
    set -l process_arch (file -b (ps -p $pid -o comm= | string trim))
    set -l binary_path (lsof -p $pid | string match -r "Terraria.*\.bin\.osx" | head -n1 | awk '{print $9}')

    echo
    gum style --foreground "#7aa2f7" --bold "Terraria Process Info:"
    echo

    # check architecture (native vs rosetta)
    if string match -q "*arm64*" $process_arch
        gum join --horizontal \
            (gum style "• Runtime: ") \
            (gum style --foreground "#9ece6a" "Native (ARM64)")
    else
        gum join --horizontal \
            (gum style "• Runtime: ") \
            (gum style --foreground "#f7768e" "Rosetta 2 (x86_64)")
    end

    # check graphics api using otool
    if test -n "$binary_path"
        set -l libs (otool -L "$binary_path" 2>/dev/null)
        gum join --horizontal \
            (gum style "• Graphics: ") \
            (begin
                if string match -q "*MoltenVK*" $libs
                    gum style --foreground "#9ece6a" "Vulkan (MoltenVK)"
                else if string match -q "*Metal.framework*" $libs
                    gum style --foreground "#9ece6a" "Metal"
                else if string match -q "*OpenGL*" $libs
                    gum style --foreground "#9ece6a" "OpenGL"
                else if string match -q "*libFNA3D*" $libs
                    # FNA3D usually means Metal on macOS
                    gum style --foreground "#9ece6a" "Metal (FNA3D)"
                else
                    gum style --foreground "#7aa2f7" "Unknown"
                end
            end)
    end

    # print pid and binary path
    gum join --horizontal \
        (gum style "• PID: ") \
        (gum style --foreground "#7aa2f7" $pid)

    if test -n "$binary_path"
        gum join --horizontal \
            (gum style "• Path: ") \
            (gum style --foreground "#7aa2f7" $binary_path)
    end

    __verify_terraria_native

    # verify terraria is still running
    while pgrep -f "Terraria\.app|Terraria\.bin\.osx" >/dev/null
        sleep 1
    end

    # cleanup handler when terraria exits
    functions -e __cleanup_terraria
    gum log -l info "Terraria process exited"
end

function __verify_terraria_native
    set -l terraria_app "$HOME/Library/Application Support/Steam/steamapps/common/Terraria/Terraria.app"
    set -l required_files
    # Executables
    set -a required_files "Contents/MacOS/Terraria.bin.osx"
    set -a required_files "Contents/MacOS/TerrariaServer.bin.osx"

    echo
    gum style --foreground "#7aa2f7" --bold "Terraria Native Installation Verification:"
    echo

    # First check the MonoKickstart script
    set -l kickstart_path "$terraria_app/Contents/MacOS/Terraria"
    if test -f "$kickstart_path"
        gum join --horizontal \
            (gum style "• MonoKickstart Script: ") \
            (begin
                set -l has_rosetta (grep -i "rosetta" "$kickstart_path")
                if test -n "$has_rosetta"
                    gum style --foreground "#f7768e" "Contains Rosetta references ✗"
                    gum log -l debug "Found in script: $has_rosetta"
                else
                    gum style --foreground "#9ece6a" "Clean ✓"
                end
            end)
    end

    # Check all dylib dependencies recursively
    for file in $required_files
        set -l full_path "$terraria_app/$file"

        gum join --horizontal \
            (gum style "• $file: ") \
            (begin
                if test -f "$full_path"
                    set -l arch (file -b "$full_path")
                    set -l deps (otool -L "$full_path" 2>/dev/null)
                    gum log -l debug "File: $full_path"
                    gum log -l debug "Architecture: $arch"
                    gum log -l debug "Dependencies: $deps"
                    
                    if string match -q "*arm64*" $arch
                        # Check if any dependencies are x86_64
                        set -l x86_deps (echo $deps | grep -i "x86_64")
                        if test -n "$x86_deps"
                            gum style --foreground "#f7768e" "ARM64 but has x86_64 deps ✗"
                        else
                            gum style --foreground "#9ece6a" "ARM64 ✓"
                        end
                    else
                        gum style --foreground "#f7768e" "x86_64 ✗"
                    end
                else
                    gum style --foreground "#f7768e" "Missing ✗"
                end
            end)
    end

    # Check Steam's launch options
    set -l steam_config "$HOME/Library/Application Support/Steam/config/config.vdf"
    if test -f "$steam_config"
        gum join --horizontal \
            (gum style "• Steam Launch Options: ") \
            (begin
                set -l has_rosetta (grep -i "rosetta" "$steam_config" | grep -i "terraria")
                if test -n "$has_rosetta"
                    gum style --foreground "#f7768e" "Forces Rosetta ✗"
                    gum log -l debug "Found in Steam config: $has_rosetta"
                else
                    gum style --foreground "#9ece6a" "Native ✓"
                end
            end)
    end

    echo
end
