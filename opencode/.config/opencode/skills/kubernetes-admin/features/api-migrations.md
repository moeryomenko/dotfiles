# API Migrations — v1.36 deprecation/removal tables, admin-scoped migration

> Migration is safe when you know exactly what v1.36 removed (not an API version), test with disabled API versions first, and rewrite both manifests and stored objects before the old versions stop being served.

## Rules

1. Do not invent a v1.36 API group/version removal; v1.36 removed **no** API group/version — the last API-version removals were in v1.32 (`flowcontrol.apiserver.k8s.io/v1beta3`). Why: the deprecation guide has no v1.36 entry, so any such row would be fabricated.
2. Treat the v1.36 `gitRepo` volume driver removal as a **volume driver removal, not an API version removal**; `core/v1` remains served and the Pod field is permanently disabled. Why: the change is in kubelet behavior, not API surface.
3. Treat Service `.spec.externalIPs` as **deprecated in v1.36 with removal planned v1.43**, not already removed. Why: the field still functions and emits warnings in v1.36.
4. Migrate off the core/v1 `Endpoints` API, deprecated since v1.33, to `discovery.k8s.io/v1` EndpointSlices.
5. Locate deprecated-API use via client deprecation warnings, metrics, and audit records (available since 1.19). Why: warnings are the cheapest way to find old API use before an upgrade.
6. Test upcoming removals by disabling API versions on the API server with `--runtime-config=<group>/<version>=false`; `--runtime-config` also supports `api/all=false,api/v1=true`. Why: a disabled version reveals dependent clients before the real removal.
7. Use `kubectl convert` only as a separately installed plugin; it is not built into kubectl as of v1.36. Why: running it without the plugin fails with "unknown command".
8. Rewrite objects still serialized at old storage versions after upgrades: fetch using the latest supported API and write back. Why: objects at old storage versions can become undecodable later.
9. Migrate CRDs to `apiextensions.k8s.io/v1` (the only served CRD API since v1.22) with a structural schema and explicit `spec.scope`. Why: v1 CRDs reject non-structural schemas and missing scope.
10. Treat the v1.36 gogoprotobuf removal as a serialization dependency change, not an API surface change. Why: no manifest impact results from the library swap.
11. Use `kubeadm config migrate --old-config <file> --new-config <file>` to move kubeadm config between API versions. Why: kubeadm config files are cluster state and must not be hand-edited across versions.
12. Keep API server flags (`--runtime-config`, `--feature-gates`) consistent across control plane replicas. Why: divergent flags produce split-brain API availability.

## Shared Deprecation/Removal Tables (v1.36)

This section is shared byte-identically with `../kubernetes-developer/features/api-migrations.md` (VC-03). The two tables below are the authoritative v1.36 removal set and the cumulative prior-release context.

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

## Admin-Scoped Migration Guidance

### In-tree API removal impacts

- `gitRepo` volumes are permanently disabled in v1.36; audit workloads for `gitRepo` before upgrade and rewrite Pod specs to use an `initContainers` + `emptyDir` clone or a git-sync sidecar.
- In-tree storage drivers continue to be removed; `awsElasticBlockStore` was removed in v1.27, and `gcePersistentDisk` and `portworxVolume` are deprecated in this tree. Migrate to CSI drivers before the remaining in-tree drivers are removed.

### Control-plane / CRD effects

- CRD objects must use `apiextensions.k8s.io/v1` with structural schemas and explicit `spec.scope`; older v1beta1 CRDs fail validation (docs:reference/using-api/deprecation-guide.md:187-205).
- Keep API server flags (`--runtime-config`, `--feature-gates`) consistent across control plane replicas; divergent flags produce split-brain API availability.
- After upgrades, rewrite objects still serialized at old storage versions: fetch using the latest supported API and write back; a `StorageVersionMigration` API (`storagemigration.k8s.io/v1beta1`) exists for migrating persisted objects (docs:tasks/administer-cluster/cluster-upgrade.md:83-90; docs:concepts/overview/working-with-objects/storage-version.md:41-57,83).

### --runtime-config testing

- Add `--runtime-config=admissionregistration.k8s.io/v1beta1=false,apiextensions.k8s.io/v1beta1=false` (plus any other deprecated groups) to the API server startup args to test with deprecated APIs disabled (docs:reference/using-api/deprecation-guide.md:384-388).
- `--runtime-config` also supports `api/all=false,api/v1=true` for broad version control (docs:tasks/administer-cluster/enable-disable-api.md:14-24).

### Admission-controller impacts

- PodSecurityPolicy (removed v1.25) users must migrate to Pod Security Admission or a 3rd-party admission webhook; PSP-era `v1beta1` manifests are rejected (docs:reference/using-api/deprecation-guide.md:148-156).
- Webhook configurations must use `admissionregistration.k8s.io/v1`; required fields `sideEffects` and `admissionReviewVersions` and the changed defaults (`failurePolicy Fail`, `timeoutSeconds 10`) apply.

### kubeadm config migration

- Migrate kubeadm configs between API versions with `kubeadm config migrate --old-config <file> --new-config <file>` (docs:reference/setup-tools/kubeadm/generated/kubeadm_config/kubeadm_config_migrate.md:34).

## Good / Bad Examples

Good:
```
apiVersion: apps/v1
kind: Deployment
```
Bad:
```
apiVersion: extensions/v1beta1   # removed since v1.16; no longer accepted
kind: Deployment
```

Good:
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
```
Bad:
```
apiVersion: extensions/v1beta1   # removed since v1.16; use networking.k8s.io/v1
kind: NetworkPolicy
```

## Command Recipes

- Test with disabled API: add `--runtime-config=<group>/<version>=false` to the API server startup args, repeating the flag or comma-separating groups, e.g. `--runtime-config=admissionregistration.k8s.io/v1beta1=false,apiextensions.k8s.io/v1beta1=false` (docs:reference/using-api/deprecation-guide.md:384-388)
- Convert a manifest: `kubectl convert -f ./my-deployment.yaml --output-version apps/v1` — plugin install required (docs:reference/using-api/deprecation-guide.md:400-406)
- List available API resources: `kubectl api-resources` (flags `--api-group`, `--namespaced`, `--sort-by`, `--verbs`) (docs:reference/kubectl/generated/kubectl_api-resources/_index.md:43-52)
- Migrate kubeadm config: `kubeadm config migrate --old-config <file> --new-config <file>` (docs:reference/setup-tools/kubeadm/generated/kubeadm_config/kubeadm_config_migrate.md:34)
- Detect deprecated-object warnings in CI: rely on kubectl's client-side deprecation warnings (docs:reference/using-api/deprecation-guide.md:390-393)

## Version Notes

- No API group/version was removed in v1.36; the removals are the `gitRepo` volume driver (blog:_posts/2026/kubernetes-v1-36-release/index.md:581-592) and the `externalIPs` deprecation with removal planned v1.43 (blog:_posts/2026/kubernetes-v1-36-release/index.md:573).
- **FUTURE (v1.37)**: static pod API references to Secrets/ConfigMaps are prohibited; the `PreventStaticPodAPIReferences` gate is removed (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:32).

## Pitfalls

- Assuming `kubectl convert` exists on the PATH — it is a separately installed plugin since it was removed from kubectl.
- Converting manifests without reviewing default changes (e.g., `policy/v1beta1` PDB empty selector semantics changed to select-all).
- Forgetting `spec.scope` or structural schemas when authoring v1 CRDs.
- Only changing manifests while leaving stored objects at old storage versions, which later become undecodable.
- Treating the gogoprotobuf removal as an API change — it is a serialization dependency change with no manifest impact.

## Cross-References

- For manifest-level migration (kubectl convert plugin install, API-group/version bumps in YAML, gitRepo Pod-spec migration): `../kubernetes-developer/features/api-migrations.md`

## Doc Refs

- docs:reference/using-api/deprecation-guide.md
- docs:reference/using-api/deprecation-policy.md
- blog:_posts/2026/kubernetes-v1-36-release/index.md
- docs:concepts/services-networking/service.md
- docs:concepts/storage/volumes.md
- docs:tasks/administer-cluster/enable-disable-api.md
- docs:tasks/administer-cluster/cluster-upgrade.md
- docs:concepts/overview/working-with-objects/storage-version.md
- docs:reference/kubernetes-api/storagemigration/storage-version-migration-v1beta1.md
- docs:reference/kubectl/generated/kubectl_api-resources/_index.md
- docs:reference/setup-tools/kubeadm/generated/kubeadm_config/kubeadm_config_migrate.md
