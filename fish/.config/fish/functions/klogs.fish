function klogs
    argparse f n/namespace= context= -- $argv
    or begin
        echo "Usage: klogs [-f] [--context CONTEXT] [-n NAMESPACE] <label-selector>" >&2
        return 2
    end

    if test (count $argv) -ne 1
        echo "Usage: klogs [-f] [--context CONTEXT] [-n NAMESPACE] <label-selector>" >&2
        return 2
    end

    set -l kubectl_options
    if set -q _flag_context
        set -a kubectl_options --context "$_flag_context"
    end
    if set -q _flag_n
        set -a kubectl_options -n "$_flag_n"
    end
    set -l logs_options
    if set -q _flag_f
        set -a logs_options -f
    end

    kubectl $kubectl_options logs $logs_options -l "$argv[1]" --prefix | jq -Rr '
        try (
            capture("^\\\\[pod/(?<pod>[^/]+)/[^]]+\\\\] (?<json>\\\\{.*\\\\})$")
            | . as $line
            | ($line.json | fromjson) as $log
            | [
                "\u001b[36mpod:\u001b[0m \($line.pod)",
                (if ($log.time? | type) == "string" and $log.time != "" then "\u001b[33mtime:\u001b[0m \($log.time | split("T") | last | sub("Z$"; ""))" else empty end),
                (if $log.level? != null then "\u001b[34mlevel:\u001b[0m \($log.level)" else empty end),
                (if $log.message_type? != null then "\u001b[35mtype:\u001b[0m \($log.message_type)" else empty end),
                (if $log.message_info? != null then "\u001b[35minfo:\u001b[0m \($log.message_info)" else empty end),
                "\u001b[32mmsg:\u001b[0m \((($log.msg // $log.message // "null") | tostring | gsub("[\r\n]+"; " ")))",
                (if $log.err_cause? != null then "\u001b[31merror:\u001b[0m \($log.err_cause | tostring | gsub("[\r\n]+"; " "))" else empty end),
                (if ($log.project? // "") != "" then "\u001b[96mproject:\u001b[0m \($log.project)" else empty end),
                (if ($log.request_id? // "") != "" then "\u001b[90mrequest_id:\u001b[0m \($log.request_id)" else empty end),
                (if $log.points? != null then "\u001b[93mpoints:\u001b[0m \($log.points | tostring)" else empty end),
                (if ($log.source? | type) == "object" then "\u001b[35msource:\u001b[0m \($log.source | {file, function, line} | with_entries(select(.value != null)) | tojson)" else empty end)
            ]
            | join("\n") + "\n"
        ) catch empty
    '
end
