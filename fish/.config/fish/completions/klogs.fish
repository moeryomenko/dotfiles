function __klogs_label_selector_pending
    set -l current_token (commandline -ct)
    if string match -q -- '-*' "$current_token"
        return 1
    end

    set -l tokens (commandline -opc)
    set -e tokens[1]
    set -l expects_value 0

    for token in $tokens
        if test $expects_value -eq 1
            set expects_value 0
            continue
        end

        switch $token
            case --context -n --namespace
                set expects_value 1
            case -f
            case '-*'
            case '*'
                return 1
        end
    end

    test $expects_value -eq 0
end

function __klogs_select_label
    set -l kubectl_options
    set -l value_for
    set -l expects_value false
    set -l tokens (commandline -opc)
    set -e tokens[1]

    for token in $tokens
        if test "$expects_value" = true
            set -a kubectl_options "$value_for" "$token"
            set expects_value false
            continue
        end

        switch $token
            case --context -n --namespace
                set value_for $token
                set expects_value true
            case '--context=*'
                set -a kubectl_options --context (string replace -- '--context=' '' "$token")
            case '-n=*'
                set -a kubectl_options -n (string replace -- '-n=' '' "$token")
        end
    end

    kubectl $kubectl_options get pods -o json 2>/dev/null \
        | jq -r '.items[]?.metadata.labels // {} | to_entries[] | "\(.key)=\(.value)"' \
        | sort -u \
        | fzf --height=40% --reverse --prompt='label> '
end

complete -c klogs -f -s f -d 'Follow logs'
complete -c klogs -f -l context -r -d 'Kubernetes context'
complete -c klogs -f -s n -l namespace -r -d 'Kubernetes namespace'
complete -c klogs -f -n __klogs_label_selector_pending -a '(__klogs_select_label)' -d 'Select label selector'
