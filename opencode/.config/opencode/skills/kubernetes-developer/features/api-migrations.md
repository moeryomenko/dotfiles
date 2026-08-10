# API Migrations — v1.36 deprecation/removal tables, manifest-level migration

> Migration is safe when you know exactly what v1.36 removed (not an API version), convert manifests with the kubectl-convert plugin, and bump API groups before the old versions stop being served.

## Rules

1. Do not invent a v1.36 API group/version removal; v1.36 removed **no** API group/version — the last API-version removals were in v1.32 (`flowcontrol.apiserver.k8s.io/v1beta3`). Why: the deprecation guide has no v1.36 entry, so any such row would be fabricated.
2. Treat the v1.36 `gitRepo` volume driver removal as a **volume driver removal, not an API version removal**; `core/v1` remains served and the Pod field is permanently disabled. Why: the change is in kubelet behavior, not API surface.
3. Treat Service `.spec.externalIPs` as **deprecated in v1.36 with removal planned v1.43**, not already removed. Why: the field still functions and emits warnings in v1.36.
4. Migrate off the core/v1 `Endpoints` API, deprecated since v1.33, to `discovery.k8s.io/v1` EndpointSlices.
5. Follow the documented migration workflow: (1) test with deprecated APIs disabled (`--runtime-config=<group>/<version>=false` on kube-apiserver), (2) locate deprecated-API usage via client deprecation warnings (v1.19+), metrics, or audit, (3) migrate manifests and clients to the non-deprecated APIs. Why: warnings are the cheapest way to find old API use before an upgrade.
6. Install `kubectl-convert` as a plugin; it is not built into kubectl as of v1.36. Why: running it without the plugin fails with "unknown command".
7. Convert manifests with `kubectl convert -f <file> --output-version <group>/<version>`, then review the output against the API reference. Why: conversion may use non-ideal default values.
8. Bump API groups/versions in YAML by hand or via convert for the historical removals still present in migrated manifests (e.g. `extensions/v1beta1` workloads, `batch/v1beta1` CronJob, `policy/v1beta1` PDB, `autoscaling/v2beta2`). Why: those versions stopped being served years ago.
9. Remember the deprecation policy: GA APIs may be deprecated but must not be removed within a major version; beta APIs are served for at least 9 months/3 minor releases after deprecation; alpha APIs may be removed in any release without notice. Why: the policy defines how long you have to migrate.
10. Migrate gitRepo volumes by mounting an `emptyDir` and cloning the repo from an init container (or use a git-sync sidecar). Why: the gitRepo volume driver is permanently disabled in v1.36.
11. Plan externalIPs removal by replacing `externalIPs` with `type: LoadBalancer` (cloud-managed), `NodePort`, or Gateway API before v1.43. Why: the field emits warnings now and will be removed.
12. CRD/API-server migrations are admin-scoped (see kubernetes-admin `features/api-migrations.md`); dev scope covers only manifest/API-group bumps. Why: control-plane changes are outside application-authoring concerns.

## Shared Deprecation/Removal Tables (v1.36)

This section is shared byte-identically with `../kubernetes-admin/features/api-migrations.md` (VC-03). The two tables below are the authoritative v1.36 removal set and the cumulative prior-release context.

### v1.36 removals/deprecations (authoritative)

| API group / object | Version / field | Status in v1.36 | Replacement | Migration path | Doc ref |
|---|---|---|---|---|---|
| core/v1 Pod `spec.volumes[].gitRepo` (gitRepo volume driver, in-tree) | field removal; driver permanently disabled | REMOVED in v1.36 (cannot be re-enabled; driver code removed from kubelet in v1.33, gate removal planned v1.39) | init container cloning a repo into `emptyDir`; external `git-sync` style tools | Rewrite Pod specs to drop `gitRepo` volumes; add `initContainers` + `emptyDir` mount (or git-sync sidecar); audit workloads for `gitRepo` before upgrade | blog/_posts/2026/kubernetes-v1-36-release/index.md; concepts/storage/volumes.md; blog/_posts/2025/kubernetes-v1-33-release/index.md |
| core/v1 Service `.spec.externalIPs` | field | DEPRECATED in v1.36 (warnings on use; full removal planned v1.43) | `type: LoadBalancer` (cloud-managed), `NodePort`, Gateway API | Remove `externalIPs` from Service manifests; adopt LB/NodePort/Gateway; treat CVE-2020-8554 as motivation | blog/_posts/2026/kubernetes-v1-36-release/index.md; concepts/services-networking/service.md; blog/_posts/2026/deprecation-of-service-externalips.md |

**Important**: v1.36 removed NO API group/version. The `reference/using-api/deprecation-guide.md` in this checkout lists removals only through v1.32 and has no v1.36 section; the v1.36 rows above are sourced from the v1.36 release blog post and `concepts/storage/volumes.md`. Any feature file claiming an API-version removal in v1.36 would be wrong per the docs.

Also deprecated-but-served in the v1.36 era: `Endpoints` API (core/v1) deprecated since v1.33, replacement `discovery.k8s.io/v1` EndpointSlice (docs:concepts/services-networking/service.md:310-322).

### Historical API-version removals (context for migration; from deprecation-guide.md)

| API group | Version removed | Removed in | Replacement | Migration path |
|---|---|---|---|---|
| flowcontrol.apiserver.k8s.io (FlowSchema, PriorityLevelConfiguration) | v1beta3 | v1.32 | flowcontrol.apiserver.k8s.io/v1 (since v1.29) | Bump apiVersion; note `nominalConcurrencyShares` defaulting change |
| flowcontrol.apiserver.k8s.io | v1beta2 | v1.29 | v1 (or v1beta3, since v1.26) | Bump apiVersion; `assuredConcurrencyShares` renamed to `nominalConcurrencyShares` |
| storage.k8s.io (CSIStorageCapacity) | v1beta1 | v1.27 | storage.k8s.io/v1 (since v1.24) | Bump apiVersion |
| flowcontrol.apiserver.k8s.io | v1beta1 | v1.26 | v1beta2 | Bump apiVersion |
| autoscaling (HorizontalPodAutoscaler) | v2beta2 | v1.26 | autoscaling/v2 (since v1.23) | Migrate `targetAverageUtilization` to `target.averageUtilization` + `target.type: Utilization` |
| batch (CronJob) | v1beta1 | v1.25 | batch/v1 (since v1.21) | Bump apiVersion |
| discovery.k8s.io (EndpointSlice) | v1beta1 | v1.25 | discovery.k8s.io/v1 (since v1.21) | Use `nodeName`/`zone` fields, not `topology[...]` |
| events.k8s.io (Event) | v1beta1 | v1.25 | events.k8s.io/v1 (since v1.19) | `type` limited to Normal/Warning; `involvedObject` -> `regarding`; use `eventTime`, `series.*` |
| autoscaling (HorizontalPodAutoscaler) | v2beta1 | v1.25 | autoscaling/v2 (since v1.23) | `target.averageUtilization` migration |
| policy (PodDisruptionBudget) | v1beta1 | v1.25 | policy/v1 (since v1.21) | Empty `spec.selector` semantics differ (v1 selects all pods) |
| policy (PodSecurityPolicy) | v1beta1 | v1.25 | Pod Security Admission / 3rd-party webhook | Migrate PSP to PSA or webhook (migrate-from-psp guide) |
| node.k8s.io (RuntimeClass) | v1beta1 | v1.25 | node.k8s.io/v1 (since v1.20) | Bump apiVersion |
| admissionregistration.k8s.io (Mutating/ValidatingWebhookConfiguration) | v1beta1 | v1.22 | admissionregistration.k8s.io/v1 (since v1.16) | Required fields: `sideEffects`, `admissionReviewVersions`; defaults changed (failurePolicy Fail, timeoutSeconds 10) |
| apiextensions.k8s.io (CustomResourceDefinition) | v1beta1 | v1.22 | apiextensions.k8s.io/v1 (since v1.16) | `spec.version`->`spec.versions`; `spec.scope` required; structural schema required |
| apiregistration.k8s.io (APIService) | v1beta1 | v1.22 | apiregistration.k8s.io/v1 (since v1.10) | Bump apiVersion |
| authentication.k8s.io (TokenReview) | v1beta1 | v1.22 | authentication.k8s.io/v1 (since v1.6) | Bump apiVersion |
| authorization.k8s.io (SubjectAccessReview etc.) | v1beta1 | v1.22 | authorization.k8s.io/v1 (since v1.6) | `spec.group` -> `spec.groups` |
| certificates.k8s.io (CertificateSigningRequest) | v1beta1 | v1.22 | certificates.k8s.io/v1 (since v1.19) | `spec.signerName`/`spec.usages` required; no legacy-unknown |
| coordination.k8s.io (Lease) | v1beta1 | v1.22 | coordination.k8s.io/v1 (since v1.14) | Bump apiVersion |
| networking.k8s.io (Ingress, IngressClass) | v1beta1 | v1.22 | networking.k8s.io/v1 (since v1.19) | `spec.backend`->`spec.defaultBackend`; `serviceName`/`servicePort`->`service.name`/`service.port.number`; `pathType` required |
| rbac.authorization.k8s.io (Role/ClusterRole/Binding) | v1beta1 | v1.22 | rbac.authorization.k8s.io/v1 (since v1.8) | Bump apiVersion |
| scheduling.k8s.io (PriorityClass) | v1beta1 | v1.22 | scheduling.k8s.io/v1 (since v1.14) | Bump apiVersion |
| storage.k8s.io (CSIDriver, CSINode, StorageClass, VolumeAttachment) | v1beta1 | v1.22 | storage.k8s.io/v1 | Bump apiVersion |
| extensions/v1beta1 (NetworkPolicy) | v1beta1 | v1.16 | networking.k8s.io/v1 (since v1.8) | Bump apiVersion |
| extensions/v1beta1, apps/v1beta1, apps/v1beta2 (Deployment, DaemonSet, ReplicaSet, StatefulSet) | multiple | v1.16 | apps/v1 (since v1.9) | Bump apiVersion; `selector` required/immutable; `maxSurge`/`maxUnavailable` default 25% |

Source for all rows in this table: `reference/using-api/deprecation-guide.md` (single authoritative list in the checkout).

## Manifest-Level Migration Guidance (dev-scoped)

### kubectl convert

- Install the plugin: download `kubectl-convert` from `dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert` (per-OS variants exist), place it on PATH, and verify with `kubectl convert --help` (docs:tasks/tools/install-kubectl-linux.md).
- Convert a manifest: `kubectl convert -f ./my-deployment.yaml --output-version apps/v1` (docs:reference/using-api/deprecation-guide.md). `--output-version` takes `<group>/<version>`; the output is the manifest rewritten to that version.
- Review the converted output before applying: `kubectl convert -f ./old.yaml --output-version apps/v1 | kubectl diff -f -` (plugin required). Why: convert may choose non-ideal defaults.

### API-group/version bumps in YAML

- Bump `apiVersion` strings to the still-served replacements: `extensions/v1beta1` -> `apps/v1` (workloads), `batch/v1beta1` -> `batch/v1` (CronJob), `policy/v1beta1` -> `policy/v1` (PDB), `autoscaling/v2beta2` -> `autoscaling/v2` (HPA), `flowcontrol.apiserver.k8s.io/v1beta3` -> `flowcontrol.apiserver.k8s.io/v1` (FlowSchema/PriorityLevelConfiguration). Why: those versions are no longer served.
- Validate after bumping: `kubectl apply --dry-run=server -f <file>`.

### gitRepo volume migration in Pod specs

- Replace `gitRepo` volumes with `initContainers` + `emptyDir`: the init container clones the repo into the `emptyDir`, and app containers mount it.

Good:
```yaml
volumes:
  - name: repo
    emptyDir: {}
initContainers:
  - name: git-clone
    image: alpine/git
    command: ["git", "clone", "https://example.com/repo.git", "/repo"]
    volumeMounts:
      - name: repo
        mountPath: /repo
containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
      - name: repo
        mountPath: /repo
```
Bad:
```yaml
volumes:
  - name: repo
    gitRepo:       # removed in v1.36; driver permanently disabled
      repository: https://example.com/repo.git
```

### externalIPs removal planning

- Remove `externalIPs` from Service manifests; adopt `type: LoadBalancer` (cloud-managed), `NodePort`, or Gateway API. Why: externalIPs are unmanaged by Kubernetes and deprecated with removal planned v1.43.

## Command Recipes

- Convert a manifest: `kubectl convert -f <file> --output-version <group>/<version>` — plugin install required (docs:reference/using-api/deprecation-guide.md)
- Verify the plugin: `kubectl convert --help` (docs:tasks/tools/install-kubectl-linux.md)
- Discover served API resources: `kubectl api-resources` — the exact flag surface for v1.36 is UNVERIFIED beyond the docs' index pages (docs:reference/kubectl/kubectl.md)
- Discover served API versions: `kubectl api-versions` — the exact flag surface for v1.36 is UNVERIFIED beyond the docs' index pages (docs:reference/kubectl/kubectl.md)
- Locate deprecated usage: rely on kubectl's client-side deprecation warnings, metrics, and audit records (docs:reference/using-api/deprecation-guide.md)

## Version Notes

- The built-in `kubectl convert` subcommand was removed from kubectl and moved to a plugin (kubectl issue #725) (docs:reference/using-api/deprecation-guide.md).
- Historical API-version removals that still appear in migrated manifests: see the shared table above (e.g. `extensions/v1beta1`/`apps/v1beta1|beta2` workloads removed v1.16; `batch/v1beta1` CronJob and `policy/v1beta1` PDB removed v1.25; `autoscaling/v2beta2` removed v1.26; `flowcontrol.apiserver.k8s.io/v1beta3` removed v1.32) (docs:reference/using-api/deprecation-guide.md).
- **FUTURE (v1.37)**: `kubectl run --filename/-f` planned deprecation; static Pods' API references (Secrets/ConfigMaps) become invalid; kube-proxy `ipvs` mode deprecation announced (removal expected v1.43) (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md).

## Pitfalls

- `kubectl convert` output may use non-ideal defaults; always diff the converted manifest and validate against the API reference (docs:reference/using-api/deprecation-guide.md).
- `kubectl convert` is not installed by default — running it fails with "unknown command" until the plugin is installed (docs:reference/using-api/deprecation-guide.md).
- Ingress manifests without `pathType` fail validation in networking.k8s.io/v1 (docs:concepts/services-networking/ingress.md).
- CRD/API-server migrations are admin-scoped (see `../kubernetes-admin/features/api-migrations.md`); dev-scope covers only manifest/API-group bumps (spec REQ-007).

## Cross-References

- For admin-scoped migration (in-tree API removal, control-plane/CRD impacts, `--runtime-config` testing): `../kubernetes-admin/features/api-migrations.md`
- For Ingress `pathType` requirements: `features/services-networking.md`
- For gitRepo-adjacent volume/init-container patterns: `features/workloads.md`

## Doc Refs

- docs:reference/using-api/deprecation-guide.md
- docs:reference/using-api/deprecation-policy.md
- docs:tasks/tools/install-kubectl-linux.md
- docs:concepts/storage/volumes.md
- docs:concepts/services-networking/ingress.md
