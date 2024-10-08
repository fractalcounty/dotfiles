function img2webp --description "Convert JPG and PNG files from Downloads to WebP in current directory"
    set -l options (fish_opt --short=h --long=help)
    set -a options (fish_opt --short=f --long=force)
    argparse $options -- $argv

    if set -q _flag_help
        echo "Usage: img2webp [options]"
        echo
        echo "Convert JPG and PNG files from Downloads to WebP in current directory."
        echo
        echo "Options:"
        echo "  -h, --help   Show this help message"
        echo "  -f, --force  Skip confirmation prompt"
        return 0
    end

    # Check if ImageMagick is installed
    if not command -sq magick
        gum log -l error "ImageMagick is not installed. Please install it first."
        return 1
    end

    set -l source_dir "/Users/$USER/Downloads"
    set -l target_dir (pwd)

    # Find JPG and PNG files
    set -l image_files (find "$source_dir" -type f \( -iname "*.jpg" -o -iname "*.png" \))

    if test (count $image_files) -eq 0
        gum log -l warn "No JPG or PNG files found in $source_dir."
        return 0
    end

    gum style -th prompt "The following files will be converted to WebP:"

    for file in $image_files
        echo (gum format -- "- `"(basename $file)"`")
    end
    echo

    if not set -q _flag_force
        if not gum confirm "Convert these files to WebP?"
            gum log -l warn "Operation cancelled."
            return 1
        end
    end

    set -l success_count 0
    set -l failure_count 0

    for file in $image_files
        set -l basename (basename $file)
        set -l webp_name (string replace -r '\.[^.]+$' '.webp' $basename)
        set -l target_file "$target_dir/$webp_name"

        gum spin --title "Converting "(gum style -th code "$basename") -- magick "$file" -quality 75 "$target_file"

        if test $status -eq 0
            set success_count (math $success_count + 1)
        else
            set failure_count (math $failure_count + 1)
            gum log -l error "Failed to convert $basename"
        end
    end

    gum log -l info "Conversion complete."
    gum log -l info "Successfully converted: $success_count file(s)"
    if test $failure_count -gt 0
        gum log -l warn "Failed to convert: $failure_count file(s)"
    end
end
