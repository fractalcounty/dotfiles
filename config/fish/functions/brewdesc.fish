function brewdesc -d 'Show descriptions of brew installs'
    source "$__fish_config_dir/utils/styles.fish"
    brew leaves |
        xargs brew desc --eval-all |
        string replace -r '^(.*:)(\s+[^\[].*)$' '$1'(set_color normal)'$2'(set_color $PURPLE)
end
