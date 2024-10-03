function brew --wraps brew --description 'Wrapper for brew that uses 1Password CLI plugin'
    op plugin run -- brew $argv
end
