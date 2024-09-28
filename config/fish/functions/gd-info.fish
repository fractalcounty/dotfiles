function gd-info
    set -l project_file (fd -H -t f '^project\.godot$' . | head -n1)

    if test -n "$project_file"
        set -l project_dir (dirname "$project_file")
        set -l project_name (rg -m1 'config/name="(.+)"' "$project_file" -or '$1')
        set -l godot_version (rg -m1 'PackedStringArray\("(\d+\.\d+)"' "$project_file" -or '$1')
        
        if test -n "$project_name" -a -n "$godot_version"
            printf "%s 🎮 %s" "$godot_version" "$project_name"
        else
            printf "Unknown"
        end
    else
        printf "Unknown"
    end
end

if not status --is-interactive
    gd-info
end