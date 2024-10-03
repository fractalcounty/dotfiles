function openai --wraps openai --description 'Wrapper for openai that uses 1Password CLI plugin'
    op plugin run -- openai $argv
end
