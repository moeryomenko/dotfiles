#!/bin/sh

# Kubernetes context/namespace display for tmux status bar.
# Supports:
#   - Default ~/.kube/config
#   - Custom KUBECONFIG from mise, direnv, or environment
#   - kubectx/kubens plugins with fallback to raw kubectl

if ! command -v kubectl >/dev/null 2>&1; then
    exit 0
fi

# If KUBECONFIG is not set, try to resolve it from mise for the active
# tmux pane directory. This supports project-local kubeconfigs like
# mise.toml's [env] KUBECONFIG = "{{config_root}}/kubeconfig".
if [ -z "${KUBECONFIG:-}" ] && command -v mise >/dev/null 2>&1; then
    pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)
    eval "$(mise env -C "$pane_path" -s bash 2>/dev/null)"
fi

# Get current context
if command -v kubectl-ctx >/dev/null 2>&1; then
    context=$(kubectl ctx -c 2>/dev/null)
else
    context=$(kubectl config current-context 2>/dev/null)
fi

# Get current namespace
if command -v kubectl-ns >/dev/null 2>&1; then
    namespace=$(kubectl ns -c 2>/dev/null)
else
    namespace=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
fi

if [ -n "$context" ]; then
    # Output icon + value as a single format segment so tmux status bar
    # can show/hide the entire section. Empty output = nothing displayed.
    # Include separators so the entire kube section (|  context:ns |)
    # atomically appears/disappears from the status bar.
    echo "|#[fg=blue]  #[fg=default]${context}:${namespace:-default} "
fi
