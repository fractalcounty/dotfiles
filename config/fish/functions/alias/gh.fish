function gh --wraps gh --description 'Wrapper for GitHub CLI that uses 1Password CLI plugin'
    op plugin run -- gh $argv
end
