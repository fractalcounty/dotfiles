function paths --description 'Prettify $PATH output using gum'
    set path_list (string split ':' $PATH)
    for path in $path_list
        gum style "$path" -th output
    end
end
