function gd-find
    set -l current_dir (pwd)
    while test "$current_dir" != "/"
        if test -f "$current_dir/project.godot"
            echo "$current_dir/project.godot"
            return 0
        end
        set current_dir (dirname "$current_dir")
    end
    return 1
end

if not status --is-interactive
    gd-find
end