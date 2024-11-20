function towebp --description "Convert image files to WebP format"
    set -l options (fish_opt --short=h --long=help)
    set -a options (fish_opt --short=f --long=force)
    set -a options (fish_opt --short=e --long=ext --required-val)
    set -a options (fish_opt --short=q --long=quality --required-val)
    argparse $options -- $argv

    if set -q _flag_help
        echo "Usage: towebp [options] <directory>"
        echo
        echo "Convert image files to WebP format recursively"
        echo
        echo "Options:"
        echo "  -h, --help           Show this help message"
        echo "  -f, --force          Skip confirmation prompt"
        echo "  -e, --ext=EXT        Source file extension (default: jpeg)"
        echo "  -q, --quality=NUM    WebP quality 0-100 (default: lossless)"
        echo
        echo "Examples:"
        echo "  towebp -e jpg ~/Pictures/Photos     # Convert to lossless WebP"
        echo "  towebp -e jpg -q 90 ./images       # Convert with 90% quality"
        echo "  towebp .                           # Convert current directory"
        return 0
    end

    # Check for required commands
    if not command -sq magick
        gum log -l error "ImageMagick is required but not installed."
        return 1
    end

    # Ensure directory is provided and resolve it
    set -l dir $PWD
    if set -q argv[1]
        if string match -q -- "*/*" $argv[1]
            # If path contains slashes, join with PWD
            set dir "$PWD/$argv[1]"
        else
            set dir "$PWD/$argv[1]"
        end
    end

    # Clean up any double slashes and trailing slashes
    set dir (string replace -r '/+' '/' "$dir")
    set dir (string replace -r '/$' '' "$dir")

    if not test -d "$dir"
        gum log -l error "Directory '$argv[1]' not found or not accessible."
        return 1
    end

    # Set extension with default
    set -l ext jpeg
    if set -q _flag_ext
        set ext $_flag_ext
    end

    # Set up ImageMagick quality settings
    set -l quality_args "-quality 100"
    if set -q _flag_quality
        if not string match -qr '^[0-9]+$' $_flag_quality; or test $_flag_quality -gt 100
            gum log -l error "Quality must be a number between 0 and 100"
            return 1
        end
        set quality_args "-quality $_flag_quality"
    end

    # Find all matching images recursively
    set -l images (command find $dir -type f -iname "*.$ext")
    set -l count (count $images)

    if test $count -eq 0
        gum log -l info "No .$ext files found in $dir"
        return 0
    end

    gum style -th prompt "Found $count .$ext files to convert:"
    echo

    for img in $images[1..3]
        # Show paths relative to PWD
        set -l rel_path (string replace "$PWD/" "" "$img")
        echo (gum format -- "- `$rel_path`")
    end

    if test $count -gt 3
        echo (gum format -- "- _...and "(math $count - 3)" more_")
    end
    echo

    # Show quality setting in confirmation
    set -l quality_msg lossless
    if set -q _flag_quality
        set quality_msg "quality $_flag_quality"
    end

    if not set -q _flag_force
        if not gum confirm "Convert these files to WebP ($quality_msg)?"
            gum log -l warn "Operation cancelled."
            return 1
        end
    end

    set -l converted 0
    set -l errors 0

    for img in $images
        set -l webp_path (string replace -r "\.$ext\$" ".webp" $img)
        set -l rel_path (string replace "$PWD/" "" "$img")

        if gum spin --title "Converting "(gum style -th code $rel_path) \
                -- magick $img $quality_args $webp_path
            set converted (math $converted + 1)
            rm -f $img
        else
            set errors (math $errors + 1)
            gum log -l error "Failed to convert $rel_path"
        end
    end

    if test $errors -eq 0
        gum log -l info "Successfully converted $converted files to WebP ($quality_msg)."
    else
        gum log -l warn "Converted $converted files to WebP with $errors errors."
    end
end
