function wrangler --wraps wrangler --description 'Wrapper for wrangler that uses 1Password CLI plugin'
    op plugin run -- wrangler $argv
end
