# reference to anthropic API key secret from 1Password
set -g ANTHROPIC_SECRET_REF "op://Development/Anthropic/macbook"

# system prompt as a script-level constant with role definition and structured format
set -g SYSTEM_PROMPT "You are a Git Commit Message Expert with years of experience analyzing version control diffs and crafting precise, meaningful commit messages. Your specialty is generating high-quality conventional commit messages that perfectly capture the essence of code changes.

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

function gc --description "Generate commit message using Claude AI and commit changes"

    # check if we're in a git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        gum log -l error "Not in a git repository"
        return 1
    end

    # check if ANTHROPIC_API_KEY is set
    if not set -q ANTHROPIC_API_KEY
        gum log -l info "Setting ANTHROPIC_API_KEY from $ANTHROPIC_SECRET_REF"
        echo

        if test -z "$ANTHROPIC_SECRET_REF" || not string match -q 'op://*' "$ANTHROPIC_SECRET_REF"
            gum log -l error "Invalid secret reference format"
            return 1
        end

        if not setsecret ANTHROPIC_API_KEY "$ANTHROPIC_SECRET_REF"
            gum log -l error "Failed to set ANTHROPIC_API_KEY from $ANTHROPIC_SECRET_REF"
            return 1
        end
    end

    # check staged changes
    set -l diff_context (git diff --cached --diff-algorithm=minimal)
    if test -z "$diff_context"
        if not gum confirm --prompt.foreground="$theme_blue" "No staged changes. Stage all changes?"
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

    # prepare the api payload with role and prefill
    set -l json_payload (echo '{
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 1000,
        "temperature": 0.3,
        "system": '(echo $SYSTEM_PROMPT | jq -R -s .)' ,
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
    gum log -l debug "API payload: $json_payload"

    # make the api call with spinner
    set -l response (
        gum spin --spinner.foreground="$theme_blue" \
            --title="Generating commit message..." -- \
        curl -sS https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$json_payload"
    )

    # validate response
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
    gum style --foreground "$theme_blue" --bold "Generated commit message:"
    echo
    gum style -th code "$commit_message"
    echo

    # debug logging
    gum log -l debug "Full commit message: $commit_message"

    while true
        # initial satisfaction check
        if gum confirm --prompt.foreground="$theme_blue" "Are you satisfied with this message?"
            git commit -m "$commit_message"
            gum style --foreground "$theme_foreground" --margin "1 0" "Changes committed successfully"
            return 0
        end

        # if not satisfied, show edit menu
        set -l choice (gum choose --header "What would you like to do?" \
            --cursor.foreground="$theme_blue" \
            "Edit" "Regenerate" "Confirm" "Cancel")

        switch $choice
            case Edit
                # edit raw message with validation
                set -l raw_message (gum input --width 72 \
                    --header "Edit commit message (type(scope): message):" \
                    --value "$commit_message")

                # validate against conventional commit format
                if not string match -qr '^(\w+)(?:\((.*?)\))?: (.+)$' -- $raw_message
                    gum log -l error "Invalid conventional commit format"
                    return 1
                end

                set commit_message $raw_message
                echo
                gum style --foreground "$theme_blue" --bold "Updated commit message:"
                echo
                gum style -th code "$commit_message"
                echo

            case Regenerate
                gc
                return

            case Confirm
                git commit -m "$commit_message"
                gum style --foreground "$theme_foreground" --margin "1 0" "Changes committed successfully"
                return 0

            case Cancel
                gum log -l warn "Commit aborted"
                return 1
        end
    end
end
