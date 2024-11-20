# Move SYSTEM_PROMPT outside the function to make it a script-level constant
set -g SYSTEM_PROMPT "You are a Git Commit Message Expert, specializing in analyzing git diffs and generating high-quality commit messages following the Conventional Commits format.

<output_format>
{
  \"type\": \"{{type}}\",
  \"scope\": {{scope}},
  \"message\": \"{{message}}\"
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
</rules>"

function gc --description "Generate commit message using Claude AI and commit changes"

    # constants
    set -l ANTHROPIC_SECRET_REF "op://Development/Anthropic/macbook"

    # check if we're in a git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        gum log -l error "Not in a git repository"
        return 1
    end

    # validate prompt file exists
    set -l prompt_file "$PROMPTS_DIR/git-commit.txt"
    if not test -f $prompt_file
        gum log -l error "Prompt file not found: $prompt_file"
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

    # read and prepare the prompt
    set -l base_prompt (cat $prompt_file)
    set -l full_prompt "You MUST respond with ONLY a valid JSON object matching the output_format, no other text.

<git_diff>
$diff_context
</git_diff>

<recent_commits>
$recent_commits
</recent_commits>"

    # Prepare the API call - only use claude-3-5-sonnet-20241022
    set -l json_payload (echo '{
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 150,
        "temperature": 0.3,
        "system": '(echo $SYSTEM_PROMPT | jq -R -s .)' ,
        "messages": [{
            "role": "user",
            "content": '(echo $full_prompt | jq -R -s .)' 
        }]
    }')

    # Debug the payload
    gum log -l debug "API payload: $json_payload"

    # Make the API call with spinner
    set -l response (
        gum spin --spinner.foreground="$theme_blue" \
                 --title="Generating commit message..." -- \
        curl -sS https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$json_payload"
    )

    # Validate response
    if not echo $response | jq -e . >/dev/null 2>&1
        gum log -l error "Invalid JSON response from API"
        gum log -l debug "Raw response: $response"
        return 1
    end

    # Extract and parse content
    set -l content (echo $response | jq -r '.content[0].text // empty' 2>/dev/null)
    if test -z "$content"
        gum log -l error "Empty response from API"
        gum log -l debug "Raw response: $response"
        return 1
    end

    # Try to parse as JSON, strip any markdown formatting if present
    set -l cleaned_content (echo $content | string replace -r '```json\s*' '' | string replace -r '```\s*$' '' | string trim)
    if not set -l commit_data (echo $cleaned_content | jq -e '.' 2>/dev/null)
        gum log -l error "Invalid JSON in response content"
        gum log -l debug "Content: $content"
        gum log -l debug "Cleaned content: $cleaned_content"
        return 1
    end

    # Extract components with validation
    if not set -l type (echo $commit_data | jq -r '.type // empty')
        gum log -l error "Missing commit type"
        return 1
    end
    set -l scope (echo $commit_data | jq -r '.scope // empty')
    if not set -l message (echo $commit_data | jq -r '.message // empty')
        gum log -l error "Missing commit message"
        return 1
    end

    # Construct commit message
    set -l commit_message "$type"
    if test -n "$scope" -a "$scope" != null
        set commit_message "$commit_message($scope)"
    end
    set commit_message "$commit_message: $message"

    # Preview the commit message
    echo
    gum style --foreground "$theme_blue" --bold "Generated commit message:"
    echo
    gum style -th code "$commit_message"
    echo

    # Debug logging
    gum log -l debug "Full commit message: $commit_message"
    echo

    # Confirm and commit
    if gum confirm --prompt.foreground="$theme_blue" "Commit changes with this message?"
        git commit -m "$commit_message"
        gum log -l info "Changes committed successfully"
    else
        gum log -l info "Commit aborted"
        return 1
    end
end
