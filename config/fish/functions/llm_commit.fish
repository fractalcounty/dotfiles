#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#          constants (global config)           #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

## recommended: abbr for convenience
# abbr -a gc llm_commit

## required: anthropic API secret key (https://console.anthropic.com/settings/keys)
## can be set here or securely in your environment (i.e through password manager)
# set -gx ANTHROPIC_API_KEY <value>

## temperature for the LLM response (0.0 to 1.0)
set -g TEMPERATURE 0.3

## required: default mode to use (overriden with --fat/-f or --lean/-l)
# fat - higher quality, slower, higher cost
# lean - faster, cheaper, lower quality (no chain-of-thought)
set -g DEFAULT_MODE fat

## anthropic models to use (https://docs.anthropic.com/en/docs/about-claude/models)
set -g FAT_MODEL claude-3-5-sonnet-latest # model to use for fat mode
set -g LEAN_MODEL claude-3-5-haiku-20241022 # model to use for lean mode

## max amount of tokens to return in the LLM response
set -g FAT_MAX_TOKENS 300
set -g LEAN_MAX_TOKENS 100

## system prompt as a script-level constant with role definition and structured format
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
9. include chain-of-thought analysis in the analysis field
</rules>"

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

function llm_commit --description "Generate a git commit message using Claude AI and commit changes"

    # parse arguments for mode selection
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

    # check if we're in a git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        gum log -l error "Not in a git repository"
        return 1
    end

    # simplified api key check
    if not set -q ANTHROPIC_API_KEY
        gum log -l error "ANTHROPIC_API_KEY environment variable is not set"
        return 1
    else
        gum log -l debug "Using ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY"
    end

    # check staged changes
    set -l diff_context (git diff --cached --diff-algorithm=minimal)
    if test -z "$diff_context"
        echo
        if not gum confirm "No staged changes. Stage all changes?"
            return 1
        end

        # Check if there are any changes to stage at all
        set -l unstaged_changes (git diff --name-only)
        if test -z "$unstaged_changes"
            gum log -l error "No changes to commit"
            return 1
        end

        git add .
        set diff_context (git diff --cached --diff-algorithm=minimal)
    end

    # get recent commits for style reference
    set -l recent_commits (git log -3 --pretty=format:"%B" 2>/dev/null | string collect)

    # prepare the prompt with early diff context and xml tags
    set -l user_prompt "Analyze this git diff and generate a commit message:

<git_diff>
$diff_context
</git_diff>

<recent_commits>
$recent_commits
</recent_commits>"

    # select model, max tokens and prompt based on mode
    set -l model $$mode"_MODEL"
    set -l max_tokens $$mode"_MAX_TOKENS"
    set -l prompt $$mode"_PROMPT"

    # prepare the api payload with role and prefill
    set -l json_payload (echo '{
        "model": "'(echo $model)'",
        "max_tokens": '(echo $max_tokens)',
        "temperature": '(echo $TEMPERATURE)',
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

    # debug logging
    gum log -l debug "Using $mode mode with model $model"
    gum log -l debug "API payload: $json_payload"

    # make the api call with spinner
    set -l response (
        gum spin \
            --title="Generating commit message..." -- \
        curl -sS https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$json_payload"
    )

    # validate response data
    if not echo $response | jq -e . >/dev/null 2>&1
        gum log -l error "Invalid JSON response from API"
        gum log -l debug "Raw response: $response"
        return 1
    end

    # extract and parse content
    set -l content (echo $response | jq -r '.content[0].text // empty' 2>/dev/null)
    if test -z "$content"
        gum log -l error "Empty response from API"
        gum log -l debug "Raw response: $response"
        return 1
    end

    # parse json response - reconstruct the complete JSON by adding back our prefill
    set -l cleaned_content (echo $content | string replace -r '```json\s*' '' | string replace -r '```\s*$' '' | string trim)
    # Add back the opening brace and analysis field that we prefilled
    set -l complete_json "{\"analysis\": $cleaned_content"

    if not set -l commit_data (echo $complete_json | jq -e '.' 2>/dev/null)
        gum log -l error "Invalid JSON in response content"
        gum log -l debug "Content: $content"
        gum log -l debug "Cleaned content: $cleaned_content"
        gum log -l debug "Complete JSON: $complete_json"
        return 1
    end

    # debug logging of analysis
    set -l analysis (echo $commit_data | jq -r '.analysis // empty')
    if test -n "$analysis"
        gum log -l debug "Analysis: $analysis"
    end

    # extract components
    if not set -l type (echo $commit_data | jq -r '.type // empty')
        gum log -l error "Missing commit type"
        return 1
    end
    set -l scope (echo $commit_data | jq -r '.scope // empty')
    if not set -l message (echo $commit_data | jq -r '.message // empty')
        gum log -l error "Missing commit message"
        return 1
    end

    # construct commit message
    set -l commit_message "$type"
    if test -n "$scope" -a "$scope" != null
        set commit_message "$commit_message($scope)"
    end
    set commit_message "$commit_message: $message"

    # preview
    echo
    gum style "Generated commit message:"
    echo
    gum style --foreground "#c0caf5" --background "#373d5a" "$commit_message"
    echo

    # debug logging
    gum log -l debug "Full commit message: $commit_message"

    while true
        # initial satisfaction check - handle CTRL+C but allow "No" to continue to menu
        set -l satisfied (gum confirm "Are you satisfied with this message?")
        set -l status_code $status

        # If CTRL+C was pressed (status 130), abort
        if test $status_code -eq 130
            gum log -l warn "Commit aborted"
            return 1
        end

        # If satisfied (status 0), commit and exit
        if test $status_code -eq 0
            git commit -m "$commit_message"
            gum style --foreground "#a9b1d6" --margin "1 0" "Changes committed successfully"
            return 0
        end

        # If not satisfied (status 1), show edit menu
        set -l choice (gum choose --header "What would you like to do?" \
            "Edit" "Regenerate" "Submit" "Cancel")

        # Check if CTRL+C was pressed during choose
        if test $status -eq 130
            gum log -l warn "Commit aborted"
            return 1
        end

        switch $choice
            case Edit
                # edit raw message with validation
                set -l raw_message (gum input --width 72 \
                    --header "Edit commit message - type(scope): message:" \
                    --value "$commit_message")

                # validate against conventional commit format
                if not string match -qr '^(\w+)(?:\((.*?)\))?: (.+)$' -- $raw_message
                    gum log -l error "Invalid conventional commit format"
                    return 1
                end

                set commit_message $raw_message
                echo
                gum style --bold "Updated commit message:"
                echo
                gum style --foreground "#c0caf5" --background "#373d5a" "$commit_message"
                echo

            case Regenerate
                gc
                return

            case Submit
                git commit -m "$commit_message"
                gum style --foreground "#a9b1d6" --margin "1 0" "Changes committed successfully"
                return 0

            case Cancel
                gum log -l warn "Commit aborted"
                return 1
        end
    end
end
