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

# abbr -a gc llm_commit

## USAGE:
# - 'gc': generate a commit message using default mode ('fat', can be changed via 'DEFAULT_MODE' below)
# - 'gc [-f|--fat]': use fat mode (higher quality, uses Claude 3.7 with native thinking)
# - 'gc [-l|--lean]': use lean mode (decent quality, no thinking, faster, cheaper)
# - 'gc [-a|--all]': stage all files with 'git add .' before generating a commit message

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#          constants (global config)           #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

## you can also set these in your environment if you prefer (will take precedence over below)

# whether or not to cache commit messages to reduce redundant LLM calls
set -q LLMC_CACHE_RESPONSES; or set -g LLMC_CACHE_RESPONSES true

# cache directory path to use if LLMC_CACHE_RESPONSES is true ($XDG_CACHE_HOME or ~/.cache/ if not set)
# set -g LLMC_CACHE_DIR "./my/custom/llm_commit"  # uncomment to override

# whether to always run 'git add .' before executing any other logic (not recommended)
set -q LLMC_ALWAYS_ADD_ALL; or set -g LLMC_ALWAYS_ADD_ALL false

# temperature for the LLM response (0.0 to 1.0)
set -q TEMPERATURE; or set -g TEMPERATURE 0.3

# required: default mode to use when 'gc' is called without specifying mode (--fat/-f or --lean/-l)
set -q DEFAULT_MODE; or set -g DEFAULT_MODE fat

# Anthropic API version
set -q ANTHROPIC_API_VERSION; or set -g ANTHROPIC_API_VERSION 2023-06-01

# anthropic models to use for each mode (https://docs.anthropic.com/en/docs/about-claude/models)
set -q FAT_MODEL; or set -g FAT_MODEL claude-3-7-sonnet-latest
set -q LEAN_MODEL; or set -g LEAN_MODEL claude-3-5-haiku-latest

# max amount of tokens the LLM can return in each mode
set -q FAT_MAX_TOKENS; or set -g FAT_MAX_TOKENS 4500
set -q LEAN_MAX_TOKENS; or set -g LEAN_MAX_TOKENS 300

# token budget for thinking in fat mode
set -q THINKING_BUDGET; or set -g THINKING_BUDGET 4000

# fat mode system prompt (leverages native thinking)
set -g FAT_PROMPT "You are a Git Commit Message Expert specializing in analyzing version control diffs and crafting precise, meaningful conventional commit messages.

<output_format>
{
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
1. Return ONLY a valid JSON object with type, scope, and message fields
2. Message must be under 72 characters
3. Set scope to null unless changes affect a very specific component
4. NEVER include file extensions in the scope (e.g \".ts\" or \".md\")
5. If changes are broad/all-encompassing, set scope to null
6. Use imperative mood (\"add\" not \"added\")
7. Write in lowercase, no period at end
8. Be specific and descriptive yet terse
9. Focus on the actual code changes, not just file names
10. Use your extended thinking to deeply analyze the diff before formulating a commit message
</rules>

When analyzing git diffs:
1. First examine the scope of changes (files affected and how)
2. Determine the primary type of change being made
3. Identify the specific functionality or component being changed
4. Assess whether a scope is appropriate or if changes are too broad
5. Formulate a concise description that captures the essence of the change"

# lean mode system prompt (terse, no chain-of-thought reasoning)
set -g LEAN_PROMPT "You are a Git Commit Message Expert tasked with generating high-quality conventional commit messages in JSON format.

<output_format>
{
  \"type\": \"[feat/fix/build/ci/test/docs/refactor/perf/style/chore/revert]\",
  \"scope\": \"[specific component if precise changes, otherwise null]\",
  \"message\": \"[commit message]\"
}
</output_format>

<rules>
1. Return ONLY a valid JSON object with type, scope, and message fields
2. Message must be concise, terse, and under 72 characters yet meaningful
3. Return 'null' for scope UNLESS changes affect a specific component
4. Use imperative mood (\"add\" not \"added\") in all-lowercase without punctuation
5. Never include file extensions in the scope (e.g \".ts\" or \".md\")
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
- **-f, --fat**     Use fat mode (Claude 3.7 with native thinking)
- **-l, --lean**    Use lean mode (Claude 3.5 Haiku, faster, cheaper)
- **-a, --all**     Stage all files with `git add .`"
    gum format -- "# Notes:
- Requires `ANTHROPIC_API_KEY` to be set in environment
- Model, default mode, system prompts, etc. can be configured in script"
end

function _show_commit_message -a message -a is_cached
    echo
    if test -n "$is_cached"
        # split into two parts with different colors
        gum join --horizontal \
            (gum style --foreground "#7aa2f7" --bold "Proposed commit message ") \
            (gum style --foreground "#bb9af7" --bold "(cached)") \
            (gum style --foreground "#7aa2f7" ":")
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

    # Optimize diff context based on mode
    set -l diff_context
    if test "$mode" = fat
        # For fat mode: Include more context but filter noise
        set diff_context (git diff --cached \
            --diff-algorithm=histogram \
            --function-context \
            --unified=3 \
            --ignore-space-change \
            --ignore-blank-lines \
            --color=never \
            | string replace -r '^index [0-9a-f]{7}\.\.[0-9a-f]{7}.*$' '' \
            | string replace -r '^diff --git.*$' '' \
            | string collect)
    else
        # For lean mode: Minimal but essential changes
        set diff_context (git diff --cached \
            --diff-algorithm=minimal \
            --unified=1 \
            --ignore-all-space \
            --function-context \
            --color=never \
            | string replace -r '^index [0-9a-f]{7}\.\.[0-9a-f]{7}.*$' '' \
            | string replace -r '^diff --git.*$' '' \
            | string collect)
    end

    # Add git status summary for better context
    set -l status_summary (git status --porcelain=v2 | string collect)

    # Get recent commits for context
    set -l recent_commits (git log -n 5 --pretty=format:"%h %s" | string collect)

    # Modify user prompt to include status and optimize context
    set -l user_prompt "Analyze these git changes and generate a commit message:

<git_status>
$status_summary
</git_status>

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

    # Print token budget debug info
    gum log -l debug "Model: $model"
    gum log -l debug "Max tokens: $max_tokens"
    if test "$mode" = fat
        gum log -l info "Using Claude 3.7 with thinking budget: $THINKING_BUDGET"
    end

    # Prepare API payload based on mode
    set -l json_payload

    if test "$mode" = fat
        # Check if the model is Claude 3.7 (the only one supporting thinking)
        if string match -q '*claude-3-7*' $model
            # Fat mode with Claude 3.7: Use native thinking
            set json_payload (echo '{
                "model": "'(echo $model)'",
                "max_tokens": 5000,
                "thinking": {"type": "enabled", "budget_tokens": '(echo $THINKING_BUDGET)'},
                "system": '(echo $prompt | jq -R -s .)' ,
                "messages": [
                    {
                        "role": "user", 
                        "content": '(echo $user_prompt | jq -R -s .)'
                    }
                ]
            }')

        else
            # Fat mode with non-3.7 model: No thinking support
            set json_payload (echo '{
                "model": "'(echo $model)'",
                "max_tokens": '(echo $max_tokens)',
                "temperature": '(echo $temperature)',
                "system": '(echo $prompt | jq -R -s .)' ,
                "messages": [
                    {
                        "role": "user", 
                        "content": '(echo $user_prompt | jq -R -s .)'
                    }
                ]
            }')

            gum log -l warn "Model does not support thinking, using standard request"

        end
    else
        # Lean mode: No thinking
        set json_payload (echo '{
            "model": "'(echo $model)'",
            "max_tokens": '(echo $max_tokens)',
            "temperature": '(echo $temperature)',
            "system": '(echo $prompt | jq -R -s .)' ,
            "messages": [
                {
                    "role": "user", 
                    "content": '(echo $user_prompt | jq -R -s .)'
                }
            ]
        }')
    end

    set -l timeout 30
    set -l response (
        gum spin \
            --title="Generating commit message..." -- \
        timeout $timeout curl -sS https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: $ANTHROPIC_API_VERSION" \
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

    # Extract the content from the response
    set -l content

    # First, check if there's an error in the response
    set -l error_message (echo $response | jq -r '.error.message // empty' 2>/dev/null)
    if test -n "$error_message"
        gum log -l error "API error: $error_message"
        return 1
    end

    # Handle different response formats based on mode and API version
    if test "$mode" = fat
        # For fat mode with thinking: First try to find a text block
        set content (echo $response | jq -r '.content[] | select(.type == "text") | .text // empty' 2>/dev/null)

        # If that fails, try the basic format as a fallback
        if test -z "$content"
            set content (echo $response | jq -r '.content[0].text // empty' 2>/dev/null)

            # If still empty, try other possible locations
            if test -z "$content"
                set content (echo $response | jq -r '.content[-1].text // empty' 2>/dev/null)
            end
        end
    else
        # For lean mode: Use the standard format
        set content (echo $response | jq -r '.content[0].text // empty' 2>/dev/null)
    end

    if test -z "$content"
        # Print more debug info to help diagnose the issue
        gum log -l error "Empty response from API"
        gum log -l debug "Full response:"
        echo $response | jq '.'
        return 1
    end

    # Clean and parse JSON from content
    set -l cleaned_content (echo $content | string replace -r '```json\s*' '' | string replace -r '```\s*$' '' | string replace -r '^json\s*' '' | string trim)

    if not set -l commit_data (echo $cleaned_content | jq -e '.' 2>/dev/null)
        gum log -l error "Invalid JSON in response content"
        gum log -l debug "Content: $content"
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
    set -l force_add false
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
            case -a --all
                set force_add true
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

    # modify staging logic to handle force_add flag
    if test "$LLMC_ALWAYS_ADD_ALL" = true; or test "$force_add" = true
        set -l unstaged_count (git status --porcelain | count)
        if test $unstaged_count -gt 0
            git add .
            # use gum log with proper string formatting
            set -l msg (printf "Added %d file%s to index" $unstaged_count (test $unstaged_count -gt 1; and echo "s"; or echo ""))
            gum log --level info "$msg"
        end
    end

    if test -z "$(git diff --cached --name-only)"
        if test -n "$(git status --porcelain)"
            gum log -l warn "No staged changes to commit"
            echo
            # only show prompt if auto-add is disabled
            if test "$LLMC_ALWAYS_ADD_ALL" = false; and gum confirm "Would you like to add all files to the index?"
                git add .
                if test -z "$(git diff --cached --name-only)"
                    gum log -l error "No staged files contain any changes"
                    return 1
                end
            else if test "$LLMC_ALWAYS_ADD_ALL" = false
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
    set -l cached_message ""
    set -l commit_message ""
    set -l is_cached 0

    # Only check cache if enabled
    if test "$LLMC_CACHE_RESPONSES" = true
        set cached_message (_get_cached_message $staged_hash)
        if test $status -eq 0
            # Cache exists, use it initially
            set commit_message "$cached_message"
            set is_cached 1
            _show_commit_message "$commit_message" true
        end
    end

    # Generate new message if no cache or caching disabled
    if test -z "$commit_message"
        set commit_message (_generate_commit_message $mode)
        or return 1

        # Only cache if enabled
        if test "$LLMC_CACHE_RESPONSES" = true
            _cache_message $staged_hash "$commit_message"
        end
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
