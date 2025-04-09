# fish_indent_ignore_directives --no-scope-indentation
# fish_indent_ignore_directives --no-function-indentation

#* llm_commit: generate conventional commit messages using openrouter llm api
function llm_commit --description "generate conventional commit messages using openrouter llm api"
    #* -------------------------------------------------------------------------- *#
    #*                                configuration                               *#
    #* -------------------------------------------------------------------------- *#

    #* defaults (can be overridden by env vars or flags)
    set -l default_model openai/gpt-4o-mini
    set -l default_temperature 0.7
    set -l default_max_tokens 150
    set -l default_cache_responses true
    set -l default_cache_dir "$XDG_CACHE_HOME/llm_commit"
    if not set -q XDG_CACHE_HOME; or test -z "$XDG_CACHE_HOME"
        set default_cache_dir "$HOME/.cache/llm_commit"
    end

    #* constants
    set -l api_endpoint "https://openrouter.ai/api/v1/chat/completions"
    set -g max_retries 3
    set -l initial_backoff 1 # seconds
    set -g max_diff_lines 500 # guardrail against huge diffs

    #* system prompt (can be overridden by env var)
    set -l default_system_prompt \
        "you are an expert git commit message generator adhering strictly to the conventional commits specification.\n" \
        "analyze the provided git context (staged diff, status, recent commits) and generate a concise, informative commit message.\n" \
        "output *only* a valid json object in the following format:\n" \
        "{\n" \
        "  \"type\": \"[commit type]\",\n" \
        "  \"scope\": \"[scope or null]\",\n" \
        "  \"message\": \"[commit message]\"\n" \
        "}\n" \
        "valid types: feat, fix, build, chore, ci, docs, style, perf, refactor, revert, test.\n" \
        "rules:\n" \
        "- message MUST be <= 72 characters.\n" \
        "- use 'null' for scope if the change is broad or doesn't fit a specific component.\n" \
        "- scope should be a noun, lowercase, and concise (e.g., 'ui', 'api', 'docs'). avoid file extensions.\n" \
        "- message MUST be in imperative mood (e.g., 'add feature' not 'added feature').\n" \
        "- message MUST be lowercase and MUST NOT end with a period.\n" \
        "- focus on the 'what' and 'why' of the change, not the 'how'.\n" \
        "- do not include markdown formatting (like ```json) in your response."

    #* -------------------------------------------------------------------------- *#
    #*                               helper functions                             *#
    #* -------------------------------------------------------------------------- *#

    #* display help message
    function _help
        echo
        gum format -- "# llm_commit - ai-powered conventional commit message generator"
        echo
        gum format -- "# Usage:
**llm_commit** [options] [--] [git commit arguments...]"
        echo
        gum format -- "# Options:
- **-h, --help**:          show this help message and exit
- **-a, --all**:           stage all unstaged changes (\`git add .\`) before generating
- **-m, --model** \<value\>: override the llm model (default: \$LLMC_MODEL or '$default_model')
- **-t, --temp** \<value\>:  override the llm temperature (0.0-1.0, default: \$LLMC_TEMPERATURE or '$default_temperature')
- **--no-cache**:        disable response caching for this run (default: \$LLMC_CACHE_RESPONSES or '$default_cache_responses')
- **--cache**:           enable response caching for this run (overrides --no-cache)
"
        echo
        gum format -- "# Environment Variables:
- **OPENROUTER_API_KEY**: (required) your openrouter api key
- **LLMC_MODEL**:         default model to use
- **LLMC_TEMPERATURE**:   default temperature (0.0-1.0)
- **LLMC_MAX_TOKENS**:    default max tokens for llm response
- **LLMC_CACHE_RESPONSES**: enable/disable caching ('true'/'false', default: '$default_cache_responses')
- **LLMC_CACHE_DIR**:     directory for cached responses (default: '$default_cache_dir')
- **LLMC_SYSTEM_PROMPT**: override the default system prompt
"
        echo
        gum format -- "# Examples:
# generate commit message for staged changes
llm_commit

# stage all changes and generate message
llm_commit -a

# use a specific model and pass '--no-verify' to git commit
llm_commit -m anthropic/claude-3.7-sonnet -- --no-verify
"
        return 0
    end

    #* check for required dependencies
    function _check_deps
        set -l missing_deps
        for dep in git jq curl gum shasum
            if not command -q $dep
                set -a missing_deps $dep
            end
        end
        if test (count $missing_deps) -gt 0
            gum log -l error "missing required dependencies: "(string join ", " $missing_deps)
            gum log -l info "please install them (e.g., using homebrew: 'brew install "(string join " " $missing_deps)"') and try again."
            return 1
        end
        return 0
    end

    #* check prerequisites (git repo, api key)
    function _check_prereqs
        # check if inside a git repository
        if not command git rev-parse --is-inside-work-tree >/dev/null 2>&1
            gum log -l error "not inside a git repository."
            return 1
        end

        # check for openrouter api key (recommend using setsecret)
        if not set -q OPENROUTER_API_KEY; or test -z "$OPENROUTER_API_KEY"
            # attempt to load using setsecret if available
            if command -q setsecret
                gum log -l info "OPENROUTER_API_KEY not set. attempting to load from 1password..."
                #? note: replace 'op://<vault>/<item>/credential' with the actual 1password uri
                #? the user should configure this uri themselves if they use 1password
                if setsecret OPENROUTER_API_KEY "op://Development/OpenRouter/llm_commit"
                    gum log -l info "successfully loaded OPENROUTER_API_KEY from 1password."
                else
                    set -l op_status $status
                    gum log -l error "failed to load OPENROUTER_API_KEY from 1password (status: $op_status)."
                    gum log -l info "please set the OPENROUTER_API_KEY environment variable manually or configure 'setsecret'."
                    return 1
                end
            else
                gum log -l error "OPENROUTER_API_KEY environment variable is not set."
                gum log -l info "please set it before running llm_commit."
                gum log -l info "(recommendation: use 1password cli and the 'setsecret' function for secure handling)"
                return 1
            end
        end
        return 0
    end

    #* get configuration value, prioritizing flag -> env var -> default
    function _get_config -a var_name -a flag_value -a env_var -a default_value
        if test -n "$flag_value"
            echo "$flag_value"
        else if set -q $env_var; and test -n "$(eval echo \$$env_var)"
            eval echo \$$env_var
        else
            echo "$default_value"
        end
    end

    #* validate temperature value
    function _validate_temp -a temp
        if not string match -qr '^[0-9]+(\.[0-9]+)?$' -- "$temp"
            return 1 # not a number
        end
        # use awk for float comparison as 'test' and 'math' are tricky
        if not awk -v temp="$temp" 'BEGIN { exit !(temp >= 0.0 && temp <= 1.0) }'
            return 1 # out of range (awk exits 0 if in range, 1 otherwise; 'if not' flips this)
        end
        return 0
    end

    #* get optimized git diff for llm context
    function _get_git_diff
        # use flags to minimize noise and provide context
        command git diff --cached \
            --diff-algorithm=histogram \
            --patch-with-stat \
            --unified=3 \
            --ignore-space-change \
            --ignore-blank-lines \
            --color=never |
            # remove noisy header lines
            string replace -r '^diff --git.*' '' |
            string replace -r '^index [a-f0-9]+\.\.[a-f0-9]+.*' '' |
            string replace -r '^--- a/.*' '' |
            string replace -r '^\+\+\+ b/.*' '' |
            string trim
    end

    #* get git status summary
    function _get_git_status
        command git status --porcelain=v2 --branch
    end

    #* get recent commit messages
    function _get_recent_commits
        command git log -n 5 --pretty=format:"%h %s"
    end

    #* combine context, checking size limit
    function _get_combined_context
        set -l diff_content (_get_git_diff)
        set -l diff_lines (string split -n \n -- $diff_content | count)

        #* validate numeric values before comparison
        set -l validated_diff_lines "$diff_lines"
        set -l validated_max_diff_lines "$max_diff_lines"

        if not string match -qr '^[0-9]+$' -- "$validated_diff_lines"
            gum log -l warn "internal error: diff_lines ('$validated_diff_lines') is not a valid number. defaulting to 0."
            set validated_diff_lines 0
        end
        if not string match -qr '^[0-9]+$' -- "$validated_max_diff_lines"
            gum log -l warn "internal error: max_diff_lines ('$validated_max_diff_lines') is not a valid number. defaulting to 500."
            set validated_max_diff_lines 500 # fallback to original constant
        end

        #* check diff size limit
        if test "$validated_diff_lines" -gt "$validated_max_diff_lines"
            gum log -l error "staged diff has $validated_diff_lines lines, exceeding the limit of $validated_max_diff_lines."
            gum log -l info "please break your changes into smaller commits for better history and cost-efficiency."
            return 1
        end

        set -l status_content (_get_git_status)
        set -l log_content (_get_recent_commits)

        # escape context for json embedding
        set -l escaped_diff (echo -n "$diff_content" | jq -Rs .)
        set -l escaped_status (echo -n "$status_content" | jq -Rs .)
        set -l escaped_log (echo -n "$log_content" | jq -Rs .)

        # construct the combined context string
        echo "<git_diff>\n$escaped_diff\n</git_diff>\n<git_status>\n$escaped_status\n</git_status>\n<recent_commits>\n$escaped_log\n</recent_commits>"
    end

    #* calculate cache key (sha256 of diff)
    function _get_cache_key
        _get_git_diff | command shasum -a 256 | command cut -d' ' -f1
    end

    #* read from cache
    function _cache_read -a cache_dir -a cache_key
        set -l cache_file "$cache_dir/$cache_key"
        if test -f "$cache_file"
            gum log -l debug "cache hit for key: $cache_key"
            cat "$cache_file"
            return 0
        end
        gum log -l debug "cache miss for key: $cache_key"
        return 1
    end

    #* write to cache
    function _cache_write -a cache_dir -a cache_key -a content
        # ensure cache directory exists
        if not test -d "$cache_dir"
            if mkdir -p "$cache_dir"
                gum log -l debug "created cache directory: $cache_dir"
            else
                gum log -l warn "failed to create cache directory: $cache_dir. caching disabled for this run."
                return 1
            end
        end
        set -l cache_file "$cache_dir/$cache_key"
        echo -n "$content" >"$cache_file"
        if test $status -eq 0
            gum log -l debug "wrote to cache: $cache_file"
            return 0
        else
            gum log -l warn "failed to write to cache file: $cache_file"
            return 1
        end
    end

    #* call openrouter api with retries (rewritten approach)
    function _call_openrouter_api -a api_endpoint -a model -a temperature -a max_tokens -a system_prompt -a user_context
        set -l retries 0
        set -l sleep_times 1 3 5 # hardcoded sleep durations in seconds for retries 1, 2, 3
        set -l response_file (mktemp) # temporary file for curl response body
        # removed payload_file, using --data-raw instead
        set -l stderr_file (mktemp) # temporary file for curl stderr

        #* ensure mktemp succeeded for response and stderr files
        if test $status -ne 0; or not test -n "$response_file"; or not test -n "$stderr_file"
            gum log -l error "failed to create temporary files for api call."
            rm -f "$response_file" "$stderr_file" # attempt cleanup
            return 1
        end

        #* validate numeric values before loop condition
        if not string match -qr '^[0-9]+$' -- "$retries"
            gum log -l error "internal error: retries ('$retries') is not a valid number before loop."
            rm -f "$response_file" "$stderr_file"
            return 1
        end
        if not string match -qr '^[0-9]+$' -- "$max_retries"
            gum log -l error "internal error: max_retries ('$max_retries') is not a valid number before loop."
            rm -f "$response_file" "$stderr_file"
            return 1
        end

        #* retry loop
        while test "$retries" -lt "$max_retries"
            gum log -l debug "preparing api call (attempt: "(math $retries + 1)"/$max_retries)..."

            #* construct payload
            set -l payload (
                jq -nc \
                    --arg model "$model" \
                    --argjson temp "$temperature" \
                    --argjson max_tokens "$max_tokens" \
                    --arg system_prompt "$system_prompt" \
                    --arg user_context "$user_context" \
                    '{
                        model: $model,
                        temperature: $temp,
                        max_tokens: $max_tokens,
                        messages: [
                            {role: "system", content: $system_prompt},
                            {role: "user", content: $user_context}
                        ],
                        response_format: {type: "json_object"}
                    }'
            )
            if test $status -ne 0; or test -z "$payload"
                gum log -l error "failed to construct json payload using jq or payload is empty."
                rm -f "$response_file" "$stderr_file"
                return 1
            end
            gum log -l debug "payload constructed."

            #* construct curl arguments as a list (using --data-raw, adapted from test_openrouter.fish)
            set -l curl_args --request POST \
                --url "$api_endpoint" \
                --silent \
                --header "Authorization: Bearer $OPENROUTER_API_KEY" \
                --header "Content-Type: application/json" \
                --header "HTTP-Referer: llm_commit_fish_function" \
                --header "X-Title: llm commit" \
                --data-raw "$payload" \
                --output "$response_file" \
                --stderr "$stderr_file"

            #* construct masked arguments for logging
            set -l masked_curl_args $curl_args
            set -l auth_index (contains -i -- "Authorization: Bearer" $masked_curl_args)
            if set -q auth_index[1]
                set masked_curl_args[$auth_index] "Authorization: Bearer ***masked***"
            end
            # remove potentially long payload from masked args for cleaner logging
            set -l data_index (contains -i -- "--data-raw" $masked_curl_args)
            if set -q data_index[1]
                # remove --data-raw and the following payload argument
                set -e masked_curl_args[$data_index..(math $data_index + 1)]
                set -a masked_curl_args --data-raw "'***payload masked***'" # add placeholder
            end

            #* debug output: show the command being run (masked)
            gum log -l debug -- "executing curl: curl (string join ' ' -- $masked_curl_args)"

            #* execute curl with spinner, capturing stdout to response_file and stderr to stderr_file
            gum spin --spinner dot --title "Generating commit message with $model..." -- \
                command curl $curl_args # execute with args list
            set -l curl_status $status
            set -l curl_stderr (cat "$stderr_file") # read stderr content

            gum log -l debug "curl command finished."
            gum log -l debug "curl exit status: $curl_status"
            if test -n "$curl_stderr"
                gum log -l debug "curl stderr: $curl_stderr"
            else
                gum log -l debug "curl stderr: (empty)"
            end

            #* check response file content
            if test -s "$response_file"
                gum log -l debug "response file content (first 10 lines):"
                gum log -l debug (head -n 10 "$response_file")
            else
                gum log -l debug "response file is empty or non-existent: $response_file"
            end

            #* check curl status and response validity
            if test $curl_status -ne 0
                # case 1: curl command failed
                gum log -l warn "curl command failed (status $curl_status)."
                if test -n "$curl_stderr"
                    gum log -l error "curl stderr: $curl_stderr"
                end
                rm -f "$response_file" "$stderr_file" # clean up
                return 1 # indicate failure (will trigger retry logic outside this block if applicable)
            end

            # curl succeeded, now check response file
            gum log -l debug "curl command succeeded (status 0)."
            if not test -s "$response_file"
                # case 2: response file is empty
                gum log -l warn "api call failed: received empty response."
                rm -f "$response_file" "$stderr_file" # clean up
                return 1 # indicate failure (will trigger retry logic outside this block if applicable)
            end

            # response file exists and is not empty, check json validity
            set -l parsed_response (cat "$response_file" | jq -e '.')
            set -l jq_status $status
            if test $jq_status -ne 0
                # case 3: invalid json received
                gum log -l warn "api call failed: received non-json response."
                gum log -l debug "jq parsing failed (status $jq_status)."
                rm -f "$response_file" "$stderr_file" # clean up
                return 1 # indicate failure (will trigger retry logic outside this block if applicable)
            end

            # case 4: valid json received
            gum log -l info "api call successful (received valid json)."
            cat "$response_file" # output the successful response body
            rm -f "$response_file" "$stderr_file" # clean up
            return 0 # success (exit the function and the loop)

            #* retry logic
            set retries (math $retries + 1)
            if test $retries -lt $max_retries
                set -l sleep_time $sleep_times[$retries] # get sleep time based on retry count (1-based index for sleep_times)
                if test -z "$sleep_time" # fallback if index is out of bounds
                    set sleep_time 5
                    gum log -l warn "could not determine sleep time for retry $retries, falling back to 5s."
                end
                gum log -l warn "retrying in $sleep_time seconds... (attempt $retries/$max_retries)"
                sleep $sleep_time
                # continue to next iteration of the while loop
            else
                gum log -l error "api call failed after $max_retries attempts."
                rm -f "$response_file" "$stderr_file" # clean up temp files
                return 1 # permanent failure
            end
        end # end while loop

        # should only be reached if loop condition fails unexpectedly
        gum log -l error "api call loop finished unexpectedly."
        rm -f "$response_file" "$stderr_file"
        return 1
    end

    #* parse api response and extract commit components
    function _parse_response -a response_body
        gum log -l debug "parsing api response..."
        # extract content, remove potential markdown fences, trim whitespace
        set -l content_raw (echo -n "$response_body" | jq -r '.choices[0].message.content // empty')
        if test $status -ne 0; or test -z "$content_raw"
            gum log -l error "failed to extract content from api response."
            # quote variable for safety
            gum log -l debug "response body: \"$response_body\""
            return 1
        end
        # quote variable for safety
        gum log -l debug "raw content: \"$content_raw\""

        # remove potential markdown fences like ```json ... ```
        set -l content_cleaned (echo -n "$content_raw" | string replace -r '^```json\s*' '' | string replace -r '\s*```$' '' | string trim)
        # quote variable for safety
        gum log -l debug "cleaned content: \"$content_cleaned\""

        # validate if it's valid json
        if not echo -n "$content_cleaned" | jq -e . >/dev/null 2>&1
            gum log -l error "llm response is not valid json after cleaning."
            # quote variable for safety
            gum log -l debug "cleaned content was: \"$content_cleaned\""
            return 1
        end

        # extract fields
        set -l commit_type (echo -n "$content_cleaned" | jq -r '.type // empty')
        set -l commit_scope (echo -n "$content_cleaned" | jq -r '.scope // "null"') # default to "null" string if missing
        set -l commit_message_text (echo -n "$content_cleaned" | jq -r '.message // empty')

        # validate required fields
        if test -z "$commit_type"; or test -z "$commit_message_text"
            gum log -l error "llm response json is missing required fields ('type' or 'message')."
            # quote string for safety
            gum log -l debug "parsed json: type='$commit_type', scope='$commit_scope', message='$commit_message_text'"
            return 1
        end

        # handle null scope explicitly
        if test "$commit_scope" = null
            set commit_scope ""
        end

        # quote string for safety
        gum log -l debug "parsed commit: type='$commit_type', scope='$commit_scope', message='$commit_message_text'"
        # return components (use global vars or pass back via stdout lines)
        # using stdout lines for simplicity here
        echo "$commit_type"
        echo "$commit_scope"
        echo "$commit_message_text"
        return 0
    end

    #* format commit message string
    function _format_commit_message -a type -a scope -a message_text
        if test -n "$scope"
            echo "$type($scope): $message_text"
        else
            echo "$type: $message_text"
        end
    end

    #* display commit message and prompt user
    function _show_commit_message -a message -a is_cached
        echo # add spacing
        if test -n "$is_cached"
            # split into two parts with different colors
            gum join --horizontal \
                (gum style --foreground "#7aa2f7" --bold "Proposed commit message ") \
                (gum style --foreground "#bb9af7" --bold "(cached)") \
                (gum style --foreground "#7aa2f7" --bold ":")
        else
            gum style --foreground "#7aa2f7" --bold "Proposed commit message:"
        end
        echo # add spacing
        # display the message itself with background
        gum style --foreground "#c0caf5" --background "#373d5a" --padding "1 2" "$message"
        echo # add spacing
    end

    #* handle user interaction loop
    function _handle_ui -a initial_message -a is_cached -a remaining_args -a config
        set -l current_message $initial_message
        set -l current_is_cached $is_cached
        set -l commit_status 1 # default to failure

        while true
            # Clear screen before displaying menu to prevent accumulation
            clear
            _show_commit_message "$current_message" "$current_is_cached"

            # Gum displays items in the order they're defined, but we want Submit at the top
            set -l choice (gum choose --header "What would you like to do?" \
                "Submit" "Edit" "Regenerate" "Cancel")
            set -l gum_status $status

            if test $gum_status -ne 0
                gum log -l warn "user cancelled or gum choose failed (status: $gum_status)."
                set choice Cancel # treat failure as cancel
            end

            switch $choice
                case Submit
                    gum log -l info "submitting commit..."
                    # execute git commit with a more robust solution to avoid empty pathspec errors
                    # Note: use "--" to separate options from pathspecs if needed
                    command git commit -m "$current_message" --
                    set commit_status $status
                    if test $commit_status -eq 0
                        gum style --foreground "#a9b1d6" --margin "1 0" "changes committed successfully."
                        return 0 # success
                    else
                        gum log -l error "git commit command failed (status: $commit_status)."
                        # stay in loop? or exit? exiting seems safer.
                        return 1 # failure
                    end

                case Edit
                    gum log -l debug "opening editor..."
                    set -l edited_message (gum input --width 72 \
                        --header "Edit commit message - type(scope): message:" \
                        --value "$current_message")
                    set -l input_status $status

                    if test $input_status -eq 0; and test -n "$edited_message"
                        # basic validation (optional): check if format roughly matches
                        if string match -qr '^[a-z]+(\(.+\))?: .+' -- "$edited_message"
                            set current_message "$edited_message"
                            set current_is_cached "" # no longer cached
                            gum log -l debug "message updated."
                            # loop back to show updated message
                        else
                            gum log -l warn "edited message format seems invalid. keeping original."
                            # loop back without changing message
                        end
                    else
                        gum log -l warn "edit cancelled or input failed (status: $input_status)."
                        # loop back without changing message
                    end

                case Regenerate
                    gum log -l info "regenerating commit message..."
                    # signal to main loop to regenerate, bypassing cache read
                    return 10 # use a specific status code for regeneration

                case Cancel
                    gum log -l info "operation cancelled by user."
                    return 1 # failure
            end
        end
    end

    #* -------------------------------------------------------------------------- *#
    #*                                  main logic                                *#
    #* -------------------------------------------------------------------------- *#

    #* check dependencies first
    if not _check_deps
        return 1
    end

    #* parse arguments
    set -l options (fish_opt --short h --long help) \
        (fish_opt --short a --long all) \
        (fish_opt --short m --long model --required-val) \
        (fish_opt --short t --long temp --required-val) \
        (fish_opt --short N --long no-cache) \
        (fish_opt --short C --long cache)
    argparse $options -- $argv
    if test $status -ne 0
        gum log -l error "failed to parse arguments."
        _help >&2 # show help on error
        return 1
    end

    #* handle help flag
    if set -q _flag_help
        _help
        return 0
    end

    #* check prerequisites (git repo, api key)
    if not _check_prereqs
        return 1
    end

    #* handle --all flag (stage changes)
    if set -q _flag_all
        gum log -l info "staging all changes (git add .)..."
        if not command git add .
            gum log -l error "failed to stage changes (git add . failed)."
            return 1
        end
    end

    #* check if there are staged changes
    if command git diff --cached --quiet --exit-code
        gum log -l warn "no changes staged to commit."
        gum log -l info "hint: use '-a' or '--all' to stage all changes automatically, or stage files manually with 'git add'."
        return 1 # nothing to commit is not an error, but nothing to do here
    end

    #* get configuration values
    set -l model (_get_config model "$_flag_model" LLMC_MODEL "$default_model")
    set -l temperature_str (_get_config temperature "$_flag_temp" LLMC_TEMPERATURE "$default_temperature")
    set -l max_tokens (_get_config max_tokens "" LLMC_MAX_TOKENS "$default_max_tokens")
    set -l cache_dir (_get_config cache_dir "" LLMC_CACHE_DIR "$default_cache_dir")
    set -l system_prompt (_get_config system_prompt "" LLMC_SYSTEM_PROMPT "$default_system_prompt")

    #* handle cache flags (--cache overrides --no-cache)
    set -l cache_enabled_flag
    if set -q _flag_cache
        set cache_enabled_flag true
    else if set -q _flag_no_cache
        set cache_enabled_flag false
    end
    # get final cache setting: flag -> env -> default
    set -l cache_responses_str (_get_config cache_responses "$cache_enabled_flag" LLMC_CACHE_RESPONSES "$default_cache_responses")
    set -l use_caching false
    if string match -qr '^true$|^1$|^yes$' -- (string lower -- "$cache_responses_str")
        set use_caching true
    end

    #* validate temperature
    if not _validate_temp "$temperature_str"
        gum log -l error "invalid temperature value: '$temperature_str'. must be a number between 0.0 and 1.0."
        return 1
    end
    set -l temperature (math --scale=1 "$temperature_str") # ensure it's formatted as float

    # We don't actually need to pass remaining args to git commit
    # as we're using "--" to ensure there are no pathspec errors

    gum log -l debug "configuration:"
    gum log -l debug "  model: $model"
    gum log -l debug "  temperature: $temperature"
    gum log -l debug "  max_tokens: $max_tokens"
    gum log -l debug "  cache enabled: $use_caching"
    gum log -l debug "  cache dir: $cache_dir"
    # add fallback in case remaining_args is empty
    gum log -l debug "  remaining args: "(string join " " $remaining_args || echo "(none)")
    # avoid logging system prompt unless debug level is very high? it's long.
    # gum log -l debug "  system prompt: $system_prompt"

    #* main generation loop (allows for regeneration)
    set -l generated_message ""
    set -l is_cached ""
    set -l force_regenerate false # flag to bypass cache read on regenerate

    while true # loop handles regeneration
        set -l cache_key ""
        set -l commit_type ""
        set -l commit_scope ""
        set -l commit_message_text ""

        #* attempt to read from cache if enabled and not forced regenerate
        if test "$use_caching" = true; and test "$force_regenerate" = false
            set cache_key (_get_cache_key)
            if test $status -ne 0; or test -z "$cache_key"
                gum log -l warn "failed to generate cache key. caching disabled for this run."
                set use_caching 0 # disable caching if key generation fails
            else
                set generated_message (_cache_read "$cache_dir" "$cache_key")
                if test $status -eq 0; and test -n "$generated_message"
                    set is_cached true
                    # skip api call, go directly to ui
                else
                    set generated_message "" # ensure it's empty if cache miss
                    set is_cached ""
                end
            end
        else
            gum log -l debug "caching disabled or regeneration requested."
            set is_cached ""
            set generated_message ""
        end

        #* generate message via api if not cached
        if test -z "$generated_message"
            gum log -l info "gathering git context..."
            set -l user_context (_get_combined_context)
            if test $status -ne 0
                # error already logged by _get_combined_context (e.g., diff too large)
                return 1
            end

            gum log -l info "calling openrouter api (model: $model)..."
            set -l api_response (_call_openrouter_api "$api_endpoint" "$model" "$temperature" "$max_tokens" "$system_prompt" "$user_context")
            set -l api_call_status $status

            if test $api_call_status -ne 0
                gum log -l error "failed to get response from openrouter api."
                return 1
            end

            set -l parsed_components (_parse_response "$api_response")
            set -l parse_status $status

            if test $parse_status -ne 0
                gum log -l error "failed to parse llm response."
                gum log -l info "you can try regenerating, or manually crafting the commit message."
                # maybe offer to retry parsing or enter manually? for now, exit.
                return 1
            end

            # extract components from parsed output (assuming 3 lines: type, scope, message)
            set commit_type $parsed_components[1]
            set commit_scope $parsed_components[2]
            set commit_message_text $parsed_components[3]

            set generated_message (_format_commit_message "$commit_type" "$commit_scope" "$commit_message_text")

            #* write to cache if enabled
            if test "$use_caching" = true
                if test -z "$cache_key" # generate key if not already done (e.g., if caching was initially off)
                    set cache_key (_get_cache_key)
                end
                if test -n "$cache_key"
                    _cache_write "$cache_dir" "$cache_key" "$generated_message"
                    # ignore write errors, just log them
                end
            end
            set is_cached "" # newly generated
        end # end if not cached

        #* handle ui interaction
        set -l config_map # create a map-like structure if needed for passing config to ui
        # set config_map[model] $model ... etc.

        # Clear screen before displaying UI for the first time
        clear
        _handle_ui "$generated_message" "$is_cached" "$remaining_args" "$config_map"
        set -l ui_status $status

        if test $ui_status -eq 0 # successful commit
            return 0
        else if test $ui_status -eq 10 # regenerate requested
            gum log -l debug "regeneration requested by ui."
            set force_regenerate true # bypass cache read on next loop iteration
            set generated_message "" # clear current message
            set is_cached ""
            # continue loop
        else # cancel or error
            return 1
        end
        # flag is reset implicitly by function scope; removal fixes regeneration cache bypass
    end # end while true loop

    return 1 # should not be reached
end
