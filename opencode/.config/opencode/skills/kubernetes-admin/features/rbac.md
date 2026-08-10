# RBAC — Roles, Bindings, least privilege, service accounts, review

> RBAC is safe when the granted verbs are the minimum needed and every binding is scoped as tightly as the namespace or resource allows.

## Rules

1. Use `rbac.authorization.k8s.io/v1` for all RBAC objects; it is the current and only served API version since v1.22. Why: older `v1beta1` manifests are rejected.
2. Grant verbs on `apiGroups`, `resources`, and `resourceNames`; ClusterRoles additionally grant `nonResourceURLs`. Why: `resourceNames` is the only way to scope permissions to specific object instances.
3. Grant least privilege: `create` plus `delete` on pods or other workload resources can be escalated to namespace or cluster admin. Why: pod workloads can reach node and cluster privileges.
4. Extend built-in aggregate roles (`admin`, `edit`, `view`) via the `rbac.authorization.k8s.io/aggregate-to-<role>: "true"` label on a ClusterRole with an `aggregationRule`. Why: aggregated rules merge by label selector, so third parties can extend defaults without replacing them.
5. Inspect built-in ClusterRoles with `kubectl get clusterroles system:discovery -o yaml`; `system:discovery` and `cluster-admin` are preconfigured. Why: knowing the defaults prevents accidental duplication.
6. Prefer bound ServiceAccount tokens: kubelet fetches time-bound JWTs via the TokenRequest API and mounts them through projected volumes. Why: tokens expire on their own and are safer than long-lived secrets.
7. Set `automountServiceAccountToken: false` on the ServiceAccount or the Pod when the workload does not need the API. Why: the pod-level setting takes precedence and stops the default token from being mounted.
8. Reconcile RBAC manifests with live objects using `kubectl auth reconcile`, adding `--remove-extra-subjects` and `--remove-extra-permissions` to prune drift. Why: drift between manifests and live bindings is a common least-privilege leak.
9. Review access with `kubectl auth can-i`, using `--as` impersonation and `--subresource` checks. Why: impersonation proves what an identity can actually do, not what you think it can do.
10. Remember that a RoleBinding with `--clusterrole` still scopes the ClusterRole's permissions to the namespace. Why: the mental-model error of "cluster-wide because ClusterRole" overgrants access.
11. Create the ServiceAccount before bindings that reference it; the ServiceAccount admission controller also copies `imagePullSecrets` from the ServiceAccount into Pod specs that do not set them.
12. TokenRequest tokens are not individually invalidatable. Why: there is no single-token revocation mechanism, so rotate via short lifetimes and bound audiences.

## Good / Bad Examples

Good:
```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: acme
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
Bad:
```
apiVersion: rbac.authorization.k8s.io/v1beta1   # removed; rejected
kind: Role
metadata:
  namespace: acme
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create", "delete", "get", "list", "watch"]   # create+delete can escalate to admin
```

## Command Recipes

- Create a namespaced Role: `kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods` (docs:reference/access-authn-authz/rbac.md:931)
- Create a ClusterRole with resourceNames: `kubectl create clusterrole pod-reader --verb=get --resource=pods --resource-name=readablepod` (docs:reference/access-authn-authz/rbac.md:971)
- Create a ClusterRole for a non-resource URL: `kubectl create clusterrole "foo" --verb=get --non-resource-url=/logs/*` (docs:reference/access-authn-authz/rbac.md:989)
- Bind a user: `kubectl create rolebinding bob-admin-binding --clusterrole=admin --user=bob --namespace=acme` (docs:reference/access-authn-authz/rbac.md:1005)
- Bind a ServiceAccount: `kubectl create rolebinding myapp-view-binding --clusterrole=view --serviceaccount=acme:myapp --namespace=acme` (docs:reference/access-authn-authz/rbac.md:1011)
- Cluster-scoped binding: `kubectl create clusterrolebinding root-cluster-admin-binding --clusterrole=cluster-admin --user=root` (docs:reference/access-authn-authz/rbac.md:1027)
- Reconcile drift: `kubectl auth reconcile -f my-rbac-rules.yaml --dry-run=client`, then apply; add `--remove-extra-subjects --remove-extra-permissions` to prune (docs:reference/access-authn-authz/rbac.md:1059,1071)
- Review: `kubectl auth can-i create pods --all-namespaces`; `kubectl auth can-i list pods --as=system:serviceaccount:dev:foo -n prod`; `kubectl auth can-i get pods --subresource=log` (docs:reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i.md:38,45,54)
- Create a ServiceAccount: `kubectl create serviceaccount myapp` (docs:reference/access-authn-authz/rbac.md:1090)
- Patch default SA imagePullSecrets: `kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "myregistrykey"}]}'` (docs:tasks/configure-pod-container/configure-service-account.md:324)

## Decision Table

| Need | Object | Scope |
|---|---|---|
| Grant permissions in one namespace | Role + RoleBinding | namespaced |
| Grant permissions cluster-wide (or non-resource URLs) | ClusterRole + ClusterRoleBinding | cluster |
| Reuse one ClusterRole inside a single namespace | ClusterRole + RoleBinding | namespaced |
| Grant a cluster-scoped resource (e.g., nodes) | ClusterRole + ClusterRoleBinding | cluster |

Choose the binding kind by scope: a RoleBinding cannot grant cluster-scoped access, and a ClusterRoleBinding grants everywhere.

## Version Notes

- `rbac.authorization.k8s.io/v1` is the only served version since v1.22 (docs:reference/using-api/deprecation-guide.md:279-286).
- Bound ServiceAccount tokens via TokenRequest and projected volumes have been GA since the v1.21/v1.22 era; kubelet uses TokenRequest by default (docs:reference/access-authn-authz/service-accounts-admin.md:263).
- Fine-grained kubelet API authorization (KEP-2862) graduated to stable in v1.36; no RBAC-facing change is noted for v1.37 in the sneak peek (blog:_posts/2026/kubernetes-v1-36-release/index.md:560).

## Pitfalls

- Mixing a ClusterRole with a RoleBinding still restricts the permissions to that namespace; treat the pair as namespaced, not cluster-wide.
- Removing a member ClusterRole from an aggregation does not immediately revoke already-merged rules until the aggregation controller reconciles.
- Forgetting `automountServiceAccountToken: false` leaves the default ServiceAccount token mounted in every pod, widening the attack surface.
- `kubectl auth reconcile` with `--remove-extra-*` deletes live subjects/permissions missing from the manifest — run with `--dry-run=client` first.

## Cross-References

- For application-side security context (Pod Security Standards, seccomp, runAsNonRoot, app NetworkPolicies): `../kubernetes-developer/features/security.md`

## Doc Refs

- docs:reference/access-authn-authz/rbac.md
- docs:reference/access-authn-authz/service-accounts-admin.md
- docs:concepts/security/rbac-good-practices.md
- docs:tasks/configure-pod-container/configure-service-account.md
- docs:reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i.md
- docs:reference/kubectl/generated/kubectl_auth/kubectl_auth_reconcile.md
- docs:reference/using-api/deprecation-guide.md
