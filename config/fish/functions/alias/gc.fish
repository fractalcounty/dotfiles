function gc --description "Git commit with LLM-generated message using 1Password-secured API key"
    # try to set ANTHROPIC_API_KEY from 1Password if not already set
    setsecret OPENROUTER_API_KEY "op://Development/OpenRouter/llm_commit"
    or begin
        gum log -l error "Failed to load OpenRouter API key from 1Password"
        return 1
    end

    # call the original llm_commit function
    llm_commit $argv
end
