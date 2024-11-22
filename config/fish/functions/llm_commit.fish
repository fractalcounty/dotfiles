#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#                         llm_commit:                          #
#     a llm-powered conventional commit message generator      #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

## REQUIREMENTS:
# - 'gum' (https://github.com/charmbracelet/gum, 'brew install gum')
# - 'jq' (https://github.com/stedolan/jq, 'brew install jq')

## INSTALLATION:
# 1. Navigate to your fish functions directory, i.e `cd ~/.config/fish/functions`
# 2. Clone this script with `git clone https://github.com/jdx/llm_commit.fish`
# 3. Get an Anthropic API key (https://console.anthropic.com/settings/keys)
# 4. Set the ANTHROPIC_API_KEY env var securely in your environment, i.e w/ a password manager
#    (or directly in this script with 'set -gx ANTHROPIC_API_KEY <key>' if you're lazy like me)
# 5. Reccomended: add 'gc' alias for convenience, you can move this to your fish config if you want
abbr -a gc llm_commit

## USAGE:
# - 'gc': generate a commit message using default mode ('fat', can be changed via 'DEFAULT_MODE' below)
# - 'gc [-f|--fat]': use fat mode (higher quality, slower, more expensive)
# - 'gc [-l|--lean]': use lean mode (decent quality, no chain-of-thought reasoning, faster, cheaper)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#          constants (global config)           #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

## you can also set these in your environment if you prefer (will take precedence over below)

# cache directory path to store temporary commit messages ($XDG_CACHE_HOME or ~/.cache/ if not set)
# set -g LLMC_CACHE_DIR "./my/custom/llm_commit"  # uncomment to override

# temperature for the LLM response (0.0 to 1.0)
set -q TEMPERATURE; or set -g TEMPERATURE 0.3

# required: default mode to use when 'gc' is called without specifying mode (--fat/-f or --lean/-l)
set -q DEFAULT_MODE; or set -g DEFAULT_MODE fat

# anthropic models to use for each mode (https://docs.anthropic.com/en/docs/about-claude/models)
set -q FAT_MODEL; or set -g FAT_MODEL claude-3-5-sonnet-latest
set -q LEAN_MODEL; or set -g LEAN_MODEL claude-3-5-haiku-20241022

# max amount of tokens the LLM can return in each mode
set -q FAT_MAX_TOKENS; or set -g FAT_MAX_TOKENS 300
set -q LEAN_MAX_TOKENS; or set -g LEAN_MAX_TOKENS 100

# fat mode system prompt (uses chain-of-thought reasoning)
set -g FAT_PROMPT "You are a Git Commit Message Expert with years of experience analyzing version control diffs and crafting precise, meaningful commit messages. Your specialty is generating high-quality conventional commit messages within a JSON object that perfectly capture the essence of code changes.

<output_format>
{
  \"analysis\": \"[chain-of-thought reasoning about the changes]\",
  \"type\": \"[commit type]\",
  \"scope\": \"[scope or null]\",
  \"message\": \"[commit message]\"
}
</output_format>

<conventional_commit_types>
- feat: new features (MINOR in semver)
- fix: bug fixes (PATCH in semver)
- build: build system/environment changes
- ci: ci system configuration
- test: adding/fixing tests
- docs: documentation only changes
- refactor: code restructuring without behavior changes
- perf: performance improvements
- style: code style/formatting only
- chore: miscellaneous tasks
- revert: reverting previous commits
</conventional_commit_types>

<rules>
1. return ONLY a valid json object - no other text
2. message must be under 72 characters
3. use scope ONLY if changes affect a specific component
4. if changes are broad/all-encompassing, set scope to null
5. use imperative mood (\"add\" not \"added\")
6. write in lowercase, no period at end
7. be specific and descriptive yet terse
8. focus on the actual code changes, not just file names
9. only include chain-of-thought analysis in the analysis field
10. never include filenames in the scope if a scope is appropriate
</rules>"

# lean mode system prompt (terse, no chain-of-thought reasoning)
set -g LEAN_PROMPT "You are tasked with analyzing git diffs and generating high-quality conventional commit messages in the form of a JSON object.

<output_format>
{
  \"analysis\": \"[always null]\",
  \"type\": \"[feat/fix/build/ci/test/docs/refactor/perf/style/chore/revert]\",
  \"scope\": \"[specific component if precise changes, otherwise null]\",
  \"message\": \"[commit message]\"
}
</output_format>

<rules>
1. return ONLY a valid json object - no other text
2. ALWAYS return 'null' for the 'analysis' field
3. message must be concise, terse, and under 72 characters yet meaningful
4. return 'null' for scope UNLESS changes affect a specific component
5. use imperative mood (\"add\" not \"added\") in all-lowercase without punctuation
</rules>"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            rest of the script lol            #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

set -q LLMC_CACHE_DIR; or set -g LLMC_CACHE_DIR (
    test -n "$XDG_CACHE_HOME"; and echo "$XDG_CACHE_HOME/llm_commit"; or echo "$HOME/.cache/llm_commit"
)
mkdir -p "$LLMC_CACHE_DIR"

function _help
    echo
    gum format -- "# llm_commit - ai-powered conventional commit message generator"
    echo
    gum format -- "# Usage: 
**llm_commit** \<options\>"
    gum format -- "# Options:
- **-h, --help**    Show this help message
- **-f, --fat**     Use fat mode (higher quality, slower)
- **-l, --lean**    Use lean mode (faster, cheaper)"
    gum format -- "# Notes:
- Requires `ANTHROPIC_API_KEY` to be set in environment
- Model, default mode, system prompts, etc. can be configured in script"
end

function _show_commit_message -a message -a is_cached
    echo
    if test -n "$is_cached"
        gum style --foreground "#7aa2f7" --bold "Proposed commit message (cached):"
    else
        gum style --foreground "#7aa2f7" --bold "Proposed commit message:"
    end
    echo
    gum style --foreground "#c0caf5" --background "#373d5a" "$message"
    echo
end

function _generate_commit_message -a mode -a temp
    set -l temperature $temp
    if test -z "$temperature"
        set temperature $TEMPERATURE
    end

    set -l diff_context (git diff --cached --diff-algorithm=minimal)
    set -l recent_commits (git log -3 --pretty=format:"%B" 2>/dev/null | string collect)

    set -l user_prompt "Analyze this git diff and generate a commit message:

<git_diff>
$diff_context
</git_diff>

<recent_commits>
$recent_commits
</recent_commits>"

    set -l mode_upper (string upper $mode)
    set -l model_var $mode_upper"_MODEL"
    set -l max_tokens_var $mode_upper"_MAX_TOKENS"
    set -l prompt_var $mode_upper"_PROMPT"

    if not set -q $model_var; or not set -q $max_tokens_var; or not set -q $prompt_var
        return 1
    end

    set -l model (string replace -r '^.*$' "$$model_var" "")
    set -l max_tokens (string replace -r '^.*$' "$$max_tokens_var" "")
    set -l prompt (string replace -r '^.*$' "$$prompt_var" "")

    set -l json_payload (echo '{
        "model": "'(echo $model)'",
        "max_tokens": '(echo $max_tokens)',
        "temperature": '(echo $temperature)',
        "system": '(echo $prompt | jq -R -s .)' ,
        "messages": [
            {
                "role": "user", 
                "content": '(echo $user_prompt | jq -R -s .)'
            },
            {
                "role": "assistant",
                "content": "{\"analysis\":"
            }
        ]
    }')

    set -l timeout 10
    set -l response (
        gum spin \
            --title="Generating commit message..." -- \
        timeout $timeout curl -sS https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$json_payload"
    )
    set -l curl_status $status

    if test $curl_status -eq 124
        gum log -l error "Request timed out after $timeout seconds"
        return 1
    else if test $curl_status -ne 0
        gum log -l error "API request failed with status $curl_status"
        return 1
    end

    set -l rate_limit (echo $response | jq -r '.error.type // empty')
    if test "$rate_limit" = rate_limit_error
        gum log -l error "API rate limit exceeded. Please try again later."
        return 1
    end

    if not echo $response | jq -e . >/dev/null 2>&1
        gum log -l error "Invalid JSON response from API"
        return 1
    end

    set -l content (echo $response | jq -r '.content[0].text // empty' 2>/dev/null)
    if test -z "$content"
        gum log -l error "Empty response from API"
        return 1
    end

    set -l cleaned_content (echo $content | string replace -r '```json\s*' '' | string replace -r '```\s*$' '' | string trim)
    set -l complete_json "{\"analysis\": $cleaned_content"

    if not set -l commit_data (echo $complete_json | jq -e '.' 2>/dev/null)
        gum log -l error "Invalid JSON in response content"
        return 1
    end

    if not set -l type (echo $commit_data | jq -r '.type // empty')
        gum log -l error "Missing commit type"
        return 1
    end
    set -l scope (echo $commit_data | jq -r '.scope // empty')
    if not set -l message (echo $commit_data | jq -r '.message // empty')
        gum log -l error "Missing commit message"
        return 1
    end

    set -l commit_message "$type"
    if test -n "$scope" -a "$scope" != null
        set commit_message "$commit_message($scope)"
    end
    echo "$commit_message: $message"
end

function _get_staged_hash
    # Get a hash of staged changes to use as cache key
    git diff --cached | sha256sum | cut -d' ' -f1
end

function _get_cached_message -a hash
    set -l cache_file "$LLMC_CACHE_DIR/$hash"
    if test -f "$cache_file"
        cat "$cache_file"
        return 0
    end
    return 1
end

function _cache_message -a hash message
    echo "$message" >"$LLMC_CACHE_DIR/$hash"
end

function llm_commit
    set -l mode $DEFAULT_MODE
    set -l remaining_args

    for arg in $argv
        switch $arg
            case -h --help
                _help
                return 0
            case -f --fat
                set mode fat
            case -l --lean
                set mode lean
            case '*'
                set -a remaining_args $arg
        end
    end

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        gum log -l error "Not in a git repository"
        return 1
    end

    if not set -q ANTHROPIC_API_KEY
        gum log -l error "ANTHROPIC_API_KEY environment variable is not set"
        return 1
    end

    if test -z "$(git diff --cached --name-only)"
        if test -n "$(git status --porcelain)"
            gum log -l warn "No staged changes to commit"
            echo
            if gum confirm "Would you like to add all files to the index?"
                git add .
                if test -z "$(git diff --cached --name-only)"
                    gum log -l error "No staged files contain any changes"
                    return 1
                end
            else
                gum log -l error "Exiting without staging changes"
                return 1
            end
        else
            gum log -l error "No changes to commit"
            echo
            return 1
        end
    end

    # Get hash of staged changes
    set -l staged_hash (_get_staged_hash)
    set -l cached_message (_get_cached_message $staged_hash)
    set -l commit_message ""
    set -l is_cached 0

    if test $status -eq 0
        # Cache exists, use it initially
        set commit_message "$cached_message"
        set is_cached 1
        _show_commit_message "$commit_message" true
    else
        # No cache exists, generate new message
        set commit_message (_generate_commit_message $mode)
        or return 1
        _cache_message $staged_hash "$commit_message"
        _show_commit_message "$commit_message"
    end

    while true
        set -l choice (gum choose --header "What would you like to do?" \
            "Submit" "Edit" "Regenerate" "Cancel")

        switch $choice
            case Submit
                echo
                git commit -m "$commit_message"
                gum style --foreground "#a9b1d6" --margin "1 0" "Changes committed successfully"
                return 0

            case Edit
                set -l raw_message (gum input --width 72 \
                    --header "Edit commit message - type(scope): message:" \
                    --value "$commit_message")
                set -l input_status $status

                if test $input_status -eq 130
                    continue
                end

                if test $input_status -ne 0
                    gum log -l error "Failed to get input"
                    continue
                end

                if not string match -qr '^(\w+)(?:\((.*?)\))?: (.+)$' -- $raw_message
                    gum log -l error "Invalid conventional commit format"
                    continue
                end

                set commit_message $raw_message
                set is_cached 0 # No longer using cached version after edit
                clear
                _show_commit_message "$commit_message"

            case Regenerate
                clear
                set -l new_message (_generate_commit_message $mode 0.7)
                if test $status -eq 0
                    set commit_message $new_message
                    set is_cached 0 # No longer using cached version after regenerate
                    _cache_message $staged_hash "$commit_message" # Cache the new message
                    _show_commit_message "$commit_message"
                end
                continue

            case Cancel '*'
                gum log -l warn "Commit aborted"
                return 1
        end
    end
end
