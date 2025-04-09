#!/usr/bin/env fish

#* test_openrouter.fish
#* minimal curl test for the openrouter api

set -l OPENROUTER_API_KEY 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

#? check for api key
if not set -q OPENROUTER_API_KEY
    gum log -l error "openrouter api key not found in environment variable \$openrouter_api_key"
    exit 1
end

#* define payload components
set -l model openai/gpt-4o-mini #* use a fast/cheap model for testing
set -l system_prompt "you are a helpful assistant."
set -l user_message "what is the capital of france?"

#* construct json payload using jq for safety
#* note: using --null-input and --arg to pass shell variables securely to jq
set -l payload (jq --null-input \
    --arg model "$model" \
    --arg system_prompt "$system_prompt" \
    --arg user_message "$user_message" \
    '{
        model: $model,
        messages: [
            {role: "system", content: $system_prompt},
            {role: "user", content: $user_message}
        ]
    }')

#* check if jq failed
if test $status -ne 0
    gum log -l error "failed to construct json payload using jq."
    exit 1
end

#* construct curl arguments as a list
set -l curl_args --request POST \
    --url "https://openrouter.ai/api/v1/chat/completions" \
    --silent \
    --header "Authorization: Bearer $OPENROUTER_API_KEY" \
    --header "Content-Type: application/json" \
    --header "HTTP-Referer: http://localhost" \
    --header "X-Title: Dotfiles Test" \
    --data-raw "$payload"

#* construct masked arguments for logging
set -l masked_curl_args $curl_args
set -l auth_index (contains -i -- "Authorization: Bearer" $masked_curl_args)
if set -q auth_index[1]
    set masked_curl_args[$auth_index] "Authorization: Bearer ***masked***"
end

#* debug output: show the command being run (masked)
gum log -l debug -- "executing curl: curl (string join ' ' -- $masked_curl_args)"

#* execute curl command
curl $curl_args

#* check curl exit status
if test $status -ne 0
    gum log -l error "curl command failed with exit code $status"
    exit $status
else
    gum log -l info "curl command completed successfully."
end

exit 0
