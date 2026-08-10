# Helm — chart authoring, templating, values design, Helm vs Kustomize

> Helm manages packaged releases with their own lifecycle; Kustomize customizes plain manifests in-tree. Pick by management model, not by habit.

## Rules

1. Use Helm for packaged release management: charts bundle pre-configured resources, with reproducible builds and release lifecycle. Why: Helm is the ecosystem's package manager, not a core Kubernetes API.
2. Carry the `app.kubernetes.io/managed-by: Helm` label on Helm-managed resources. Why: the docs' recommended-label convention uses `Helm` as the canonical value.
3. Add chart repos and install releases with the documented forms: `helm repo add <name> <url>` and `helm upgrade --install <release> <chart> --create-namespace --namespace <ns>`. Why: `upgrade --install` is the idempotent install-or-upgrade form the docs use.
4. Remember `helm upgrade` cannot change an immutable Deployment selector (apps/v1 rejects it), same as any other client. Why: selector immutability is an API rule, not a Helm quirk.
5. Generate chart skeletons from Docker Compose with Kompose (`kompose convert -c`); the result is a skeleton to build on. Why: Kompose gives a starting point, not production charts.
6. Prefer Kustomize for customizing plain manifests without a templating language (native kubectl: `kubectl apply -k`, `kubectl kustomize`). Why: Kustomize is built into kubectl; see `features/manifests.md`.
7. Choose Helm vs Kustomize by management model: Helm manages packaged releases with its own lifecycle; Kustomize overlays plain manifests in-tree. Why: the docs describe the two as different approaches, not competitors with identical scope.
8. Do not manage the same resources with Helm and `kubectl apply`/Kustomize concurrently. Why: concurrent writers fight over the same fields.
9. Chart authoring/templating commands are NOT covered by k8s-site — source them from helm.sh and audit flags before use. Why: k8s-site only cites Helm incidentally (Dashboard install example).

## Good / Bad Examples

Good (documented install form):
```
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```
Bad (concurrent management — the docs' shared-label convention implies one owner):
```
kubectl apply -f ./manifests/    # applied to a release Helm also manages -> field conflicts
```

Good (Helm-managed resources carry the shared label):
```yaml
labels:
  app.kubernetes.io/managed-by: Helm
```
Bad:
```yaml
# no app.kubernetes.io/managed-by label on Helm-managed resources
```

## Command Recipes

- Add a chart repository: `helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/` (docs:tasks/access-application-cluster/web-ui-dashboard.md)
- Install or upgrade a release: `helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard` (docs:tasks/access-application-cluster/web-ui-dashboard.md)
- No-Helm paths: `kubectl create deployment <name> --image=<img>` / `kubectl apply -k <kustomization_dir>` (docs:concepts/overview/working-with-objects/object-management.md; docs:tasks/manage-kubernetes-objects/kustomization.md)

## Unverified Flags

- Chart authoring/templating commands (`helm create`, `helm template`, `helm lint`, `helm package`, `helm install --set`, `helm dependency`, `helm push`) are NOT covered by k8s-site — UNVERIFIED; source from helm.sh docs and audit before use.
- `values.yaml` schema patterns and template functions (`{{ .Values... }}`, `include`/`tpl`) are NOT covered by k8s-site — UNVERIFIED; source from helm.sh docs and audit before use.

## Version Notes

- No version-specific Helm behavior is documented in k8s-site; treat Helm versions as independent of Kubernetes v1.36 (docs:reference/tools/_index.md).
- **FUTURE (v1.37)**: no Helm-related k8s-site changes announced.

## Pitfalls

- `helm upgrade` cannot mutate Deployment selectors (immutable in apps/v1) — selector changes require delete/recreate (docs:concepts/workloads/controllers/deployment.md).
- Resources managed by Helm and by `kubectl apply` (or Kustomize) concurrently can fight over the same fields; use the shared-label convention (`app.kubernetes.io/managed-by`) (docs:concepts/overview/working-with-objects/common-labels.md).
- Because k8s-site does not document Helm templating, chart authoring command recipes must be sourced externally and audited (spec VC-04).

## Cross-References

- For Kustomize as the no-templating alternative: `features/manifests.md`
- For Deployment selector immutability: `features/workloads.md`
- For the recommended shared-label conventions: `features/manifests.md`

## Doc Refs

- docs:reference/tools/_index.md
- docs:concepts/workloads/management.md
- docs:concepts/overview/working-with-objects/common-labels.md
- docs:tasks/access-application-cluster/web-ui-dashboard.md
- docs:tasks/configure-pod-container/translate-compose-kubernetes.md
- docs:tasks/manage-kubernetes-objects/kustomization.md
- docs:concepts/workloads/controllers/deployment.md
