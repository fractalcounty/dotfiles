function setsecret --description "Set environment variable from 1Password secret" --argument-names env_var secret_ref
    # validate arguments
    if test -z "$env_var" -o -z "$secret_ref"
        gum log -l error "Usage: setsecret ENV_VAR SECRET_REF"
        gum log -l error "Example: setsecret GITHUB_TOKEN op://Development/GitHub/token"
        return 1
    end

    # check if already set
    if set -q $env_var
        return 0
    end

    # check for op cli
    if not command -q op
        gum log -l error "1Password CLI (op) not found"
        return 1
    end

    # attempt to load secret
    set -l value (timeout 5s op read "$secret_ref" 2>/dev/null)
    if test $status -eq 124
        gum log -l error "Timed out while accessing 1Password"
        return 1
    end
    if test $status -eq 0
        set -gx $env_var $value
        gum log -l debug "Set $env_var from 1Password"
        return 0
    else
        gum log -l warn "Failed to load secret from 1Password: $secret_ref"
        return 1
    end
end
