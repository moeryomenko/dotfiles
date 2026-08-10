# Manifests — authoring, labels/annotations, kustomize, YAML conventions

> Manifests are the declarative contract with the API server: get `apiVersion`/`kind`/`metadata` right, keep selectors immutable and non-overlapping, and prefer declarative apply.

## Rules

1. Every object manifest requires `apiVersion`, `kind`, and `metadata`; workloads additionally require a `spec`. Why: the API server rejects objects missing these identifying fields.
2. In a Deployment, `.spec.selector` and `.spec.template` are the only required spec fields, and the template has exactly the same schema as a Pod minus `apiVersion`/`kind`. Why: the controller matches ReplicaSets to Pods through the selector/template pair.
3. Label keys use an optional DNS-subdomain prefix (<=253 chars) plus a slash, then a name segment (<=63 chars, starts/ends with `[a-z0-9A-Z]`, interior `-`, `_`, `.`); label values are <=63 chars and may be empty. Why: labels are validated against a strict grammar at admission.
4. Treat the `kubernetes.io/` and `k8s.io/` label prefixes as reserved for core components. Why: user labels colliding with reserved prefixes can confuse controllers and tooling.
5. Annotation keys follow label-key syntax, but annotation values have NO character-set restriction (JSON/YAML/binary as base64 are allowed); keep total annotations on one object under 256 KiB. Why: annotations are meant for non-identifying metadata the API does not index.
6. Annotation keys and values must be strings — numbers, booleans, and lists are rejected. Why: the annotations map is typed as `map[string]string`.
7. Selector styles are equality-based (`=`, `==`, `!=`) and set-based (`in`, `notin`, `exists`, `!`); comma-separated requirements are ANDed and there is NO logical OR operator. Why: OR semantics are deliberately absent so controllers never get ambiguous match sets.
8. Workload controllers (Deployment/ReplicaSet/StatefulSet/DaemonSet) support set-based `matchExpressions` in addition to `matchLabels`; Service and ReplicationController selectors are equality-based only. Why: services were never given set-based selector support.
9. Adopt the recommended shared labels `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`, `app.kubernetes.io/component`, `app.kubernetes.io/part-of`, `app.kubernetes.io/managed-by` (e.g. `Helm`). Why: tooling and humans can aggregate resources across manifests consistently.
10. Never let two controllers' selectors overlap; Deployment/StatefulSet selectors are immutable after creation. Why: overlapping selectors make controllers fight over the same Pods.
11. Prefer declarative object management: `kubectl apply -f` over `kubectl create -f` or imperative `kubectl create` commands. Why: apply records desired state and last-applied config for merge behavior.
12. Do not hand-scale a manifest-managed Deployment and then re-apply: `kubectl apply` overwrites the manual scale with the manifest's `replicas` value. Why: the manifest is the source of truth for apply.
13. Use `kubectl apply --server-side` for concurrent writers, and pass `--field-manager` to avoid field-conflict errors. Why: server-side apply reports ownership of every managed field.
14. Kustomize: declare resources and generators in `kustomization.yaml`; generate ConfigMaps/Secrets via `configMapGenerator`/`secretGenerator`; set cross-cutting fields (`namespace`, `namePrefix`, `nameSuffix`, `labels`, `commonAnnotations`); patch via `patches` (strategic merge) or `patches` + `target` (JSON6902); override images via `images`; inject values via `replacements`. Why: overlays let one base serve multiple environments without a templating language.
15. Keep `generatorOptions.disableNameSuffixHash: true` only when you want stable ConfigMap/Secret names; otherwise the content-hash suffix propagates data changes automatically. Why: the hash suffix forces dependent workloads to restart when generated data changes.
16. Set `includeSelectors: true` when a `labels:` block in kustomization must also update selectors; without it, selectors and template labels drift. Why: the docs' cross-cutting example sets this flag explicitly to keep the two in sync.
17. `kubectl convert` is a plugin, not a built-in kubectl command, as of v1.36. Why: it was removed from the kubectl binary; see `features/api-migrations.md`.
18. `.kuberc` (user preferences separate from kubeconfig) is beta and enabled by default; disable with `KUBECTL_KUBERC=false` or `KUBERC=off`. Why: the format is `kubectl.config.k8s.io/v1beta1` at `$HOME/.kube/kuberc`.

## Good / Bad Examples

Good (label key syntax and reserved-prefix avoidance):
```yaml
metadata:
  labels:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/instance: prod
    tier: frontend
```
Bad:
```yaml
metadata:
  labels:
    kubernetes.io/name: myapp   # reserved prefix; not yours to use
    1bad_key: value             # invalid: starts with digit, wrong charset
```

Good (equality selector on a Deployment):
```yaml
selector:
  matchLabels:
    app.kubernetes.io/name: myapp
```
Bad (set-based selector on a Service — rejected):
```yaml
selector:
  matchExpressions:            # Service selectors are equality-based only
    - key: tier
      operator: In
      values: [frontend, backend]
```

Good (Kustomize overlay that stays in sync):
```yaml
# overlay/kustomization.yaml
resources:
  - ../base
labels:
  - pairs:
      app.kubernetes.io/part-of: myapp
    includeSelectors: true
```
Bad:
```yaml
# overlay/kustomization.yaml
resources:
  - ../base
labels:
  - pairs:
      app.kubernetes.io/part-of: myapp   # no includeSelectors -> selectors not updated
```

Good (memory units):
```yaml
resources:
  requests:
    memory: 400Mi   # 400 mebibytes
```
Bad:
```yaml
resources:
  requests:
    memory: 400m    # 0.4 bytes (millibytes) — a classic mistake
```

## Command Recipes

- Apply a file or directory (declarative, recommended): `kubectl apply -f configs/` or `kubectl apply -R -f configs/` (docs:concepts/overview/working-with-objects/object-management.md)
- Preview changes before applying: `kubectl diff -f configs/` (docs:concepts/overview/working-with-objects/object-management.md)
- Apply a Kustomize overlay: `kubectl apply -k <kustomization_dir>`; render it first with `kubectl kustomize <dir>` (docs:tasks/manage-kubernetes-objects/kustomization.md)
- Use Kustomize with other kubectl verbs: `kubectl get -k .`, `kubectl describe -k .`, `kubectl diff -k .`, `kubectl delete -k .` (docs:tasks/manage-kubernetes-objects/kustomization.md)
- Select Pods by label (equality): `kubectl get pods -l environment=production,tier=frontend` (docs:concepts/overview/working-with-objects/labels.md)
- Select Pods by label (set-based): `kubectl get pods -l 'environment in (production,qa)'` (docs:concepts/overview/working-with-objects/labels.md)
- Show label columns: `kubectl get pods -Lapp -Ltier` (`-L` == `--label-columns`) (docs:concepts/overview/working-with-objects/labels.md)
- Relabel in bulk: `kubectl label pods -l app=nginx tier=fe` (docs:concepts/overview/working-with-objects/labels.md)
- Server-side apply: `kubectl apply --server-side --field-manager=my-manager --dry-run=server` (docs:reference/using-api/server-side-apply.md)
- Apply a remote manifest: `kubectl apply -f https://k8s.io/examples/controllers/deployment.yaml` (docs:concepts/workloads/controllers/deployment.md)

## Decision Tables

Object-management technique:

| Technique | Command | Last-applied state | Best for |
|---|---|---|---|
| Imperative commands | `kubectl create deployment nginx --image nginx` | no | quick interactive work, scripts |
| Imperative config | `kubectl create -f`, `kubectl replace -f` | no | one-shot create/replace of existing objects |
| Declarative config | `kubectl apply -f`, `kubectl diff -f` | yes | reproducible, GitOps-style state |

## Version Notes

- `.kuberc` is beta (v1.34+) and enabled by default in v1.36 (docs:reference/kubectl/kuberc.md).
- **FUTURE (v1.37)**: `kubectl run --filename/-f` is planned for deprecation; the generated Pod is built purely from CLI args (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md).

## Pitfalls

- Overlapping selectors across controllers cause controllers to fight; Deployment/StatefulSet selectors cannot be changed after creation (docs:concepts/workloads/controllers/deployment.md).
- `kubectl apply` after a manual `kubectl scale` reverts the replica count to the manifest value (docs:concepts/workloads/controllers/deployment.md).
- YAML memory units are case-sensitive: `400m` memory means 0.4 bytes, not 400 MiB (docs:concepts/configuration/manage-resources-containers.md).
- Missing `pathType` on Ingress paths fails validation; see `features/services-networking.md` (docs:concepts/services-networking/ingress.md).
- Kustomize `labels:` without `includeSelectors: true` does not update selectors, so selectors and template labels drift (docs:tasks/manage-kubernetes-objects/kustomization.md).
- Annotation keys/values must be strings (no numeric/boolean/list types) (docs:concepts/overview/working-with-objects/annotations.md).

## Cross-References

- For workload controller manifests: `features/workloads.md`
- For Service/Ingress/NetworkPolicy manifests: `features/services-networking.md`
- For ConfigMap/Secret manifests: `features/config-secrets.md`
- For API-group/version bumps and `kubectl convert`: `features/api-migrations.md`
- For manifest-level security fields: `features/security.md`

## Doc Refs

- docs:concepts/overview/working-with-objects/labels.md
- docs:concepts/overview/working-with-objects/annotations.md
- docs:concepts/overview/working-with-objects/common-labels.md
- docs:concepts/overview/working-with-objects/object-management.md
- docs:tasks/manage-kubernetes-objects/kustomization.md
- docs:reference/using-api/server-side-apply.md
- docs:reference/kubectl/kuberc.md
- docs:tasks/tools/install-kubectl-linux.md
