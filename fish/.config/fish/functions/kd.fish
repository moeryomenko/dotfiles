function kd
    set -l pod $argv[1]

    if test -z "$pod"
        set pod (__k8s_select_pod)
    end

    if test -z "$pod"
        return 1
    end

    kubectl get po "$pod" -o yaml | bat -l yaml
end
