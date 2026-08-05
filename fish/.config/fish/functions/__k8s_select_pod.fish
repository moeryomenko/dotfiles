function __k8s_select_pod
    kubectl get po -o name | cut -d/ -f2 | sk --reverse --preview-window=right:75% \
        --preview 'kubectl describe po {} | bat'
end
