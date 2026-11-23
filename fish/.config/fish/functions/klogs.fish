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
            | "\u001b[36mpod:\u001b[0m \($line.pod)\n\u001b[33mtime:\u001b[0m \($log.time | split("T")[1] | sub("Z$"; ""))\n\u001b[32mmsg:\u001b[0m \($log.msg)\n\u001b[35msource:\u001b[0m \($log.source | {file, function, line} | tojson)\n"
        ) catch empty
    '
end
