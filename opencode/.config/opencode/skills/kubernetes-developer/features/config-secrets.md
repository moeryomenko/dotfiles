# Config & Secrets — ConfigMaps, Secrets, env wiring, immutable config, 12-factor patterns

> Inject configuration as data, not as image content: ConfigMaps for plain config, Secrets for sensitive data, both capped at 1 MiB and referenced explicitly from Pods.

## Rules

1. Use ConfigMaps for non-sensitive configuration; `data` holds UTF-8 strings and `binaryData` holds base64. Why: ConfigMaps are the plaintext config object.
2. Keep ConfigMaps and Secrets under 1 MiB each; use a volume or external store for larger data. Why: both are stored in etcd and capped at 1 MiB.
3. Keep ConfigMaps/Secrets in the same namespace as the consuming Pod; static Pods cannot reference ConfigMaps or Secrets. Why: cross-namespace references are not allowed (and static Pod refs become invalid in v1.37).
4. Choose the Secret type deliberately: `Opaque` (default), `kubernetes.io/tls`, `kubernetes.io/dockercfg`, `kubernetes.io/dockerconfigjson`, `kubernetes.io/basic-auth`, `kubernetes.io/ssh-auth`, `bootstrap.kubernetes.io/token`, `kubernetes.io/service-account-token`. Why: the API server validates type-specific fields.
5. Write Secret `data` as base64; use `stringData` for plaintext only when not using server-side apply. Why: `stringData` interacts poorly with SSA.
6. Do not expect secrecy from base64: Secrets are stored unencrypted in etcd by default. Why: base64 is encoding, not encryption.
7. Enable encryption at rest, least-privilege RBAC on Secrets, per-container access limits, and consider external stores (Secrets Store CSI). Why: etcd compromise would otherwise leak every Secret.
8. Consume ConfigMaps four ways: container command/args, env vars, files in a volume, or direct API reads (which can watch updates). Why: each fits a different consumption pattern.
9. Use `envFrom` to pull all keys (ConfigMap or Secret), `valueFrom.configMapKeyRef`/`secretKeyRef` for a single key, and `optional: true` when a missing key must not block the Pod. Why: a non-optional missing ref prevents Pod start.
10. Beware `envFrom` key collisions: colliding keys are silently dropped instead of failing the Pod. Why: the merge rules skip conflicting keys by design.
11. Mark ConfigMaps/Secrets `immutable: true` (v1.19+) when values are fixed; immutable objects cannot be reverted, and the cluster uses less API-server watch load for them. Why: immutability prevents accidental mutation and trims watch traffic.
12. Changing an immutable ConfigMap/Secret requires creating a new object with a new name and updating references. Why: immutability is enforced at write time.
13. Generate ConfigMaps/Secrets in Kustomize from `files:`, `envs:`, or `literals:` with content-hash name suffixes; use `generatorOptions.disableNameSuffixHash: true` to pin names. Why: the hash propagates data changes to dependent workloads.
14. Use kubectl create sources `--from-literal`, `--from-file[=key=]source`, and `--from-env-file` for quick imperative creation. Why: they cover the common single-value and file-based cases.
15. Follow the 12-factor pattern: env/secret config is injected, not baked into images. Why: injecting config keeps images portable across environments.

## Good / Bad Examples

Good (ConfigMap env wiring):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: info
---
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: app
      image: myapp:1.0
      envFrom:
        - configMapRef:
            name: app-config
```
Bad (missing key without optional):
```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: app
      image: myapp:1.0
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-user-pass
              key: password   # non-optional missing ref -> Pod never starts
```

Good (base64 Secret data):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-user-pass
type: Opaque
data:
  username: YWRtaW4=        # base64 for "admin"
```
Bad (plaintext in data):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-user-pass
data:
  username: admin           # data must be base64 -> rejected
```

Good (immutable ConfigMap):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
immutable: true
data:
  LOG_LEVEL: info
```

## Command Recipes

- Create a ConfigMap: `kubectl create configmap <name> --from-file=app.properties --from-literal=FOO=Bar --from-env-file=.env` (docs:tasks/manage-kubernetes-objects/kustomization.md; docs:concepts/configuration/configmap.md)
- Create a generic Secret from literals: `kubectl create secret generic db-user-pass --from-literal=username=admin --from-literal=password='S!B\*d$zDsb='` (docs:tasks/configmap-secret/managing-secret-using-kubectl.md)
- Create a generic Secret from files (keyed form): `kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt`; `kubectl create secret generic db-user-pass --from-file=username=./username.txt` (docs:tasks/configmap-secret/managing-secret-using-kubectl.md)
- Create a TLS Secret: `kubectl create secret tls my-tls-secret --cert=path/to/cert --key=path/to/key` (docs:tasks/configmap-secret/managing-secret-using-kubectl.md)
- Create a docker-registry Secret: `kubectl create secret docker-registry secret-tiger-docker --docker-username=<user> --docker-password=<pass> --docker-email=<email>` (docs:tasks/configmap-secret/managing-secret-using-kubectl.md)
- Edit or delete a Secret: `kubectl edit secret <name>`; `kubectl delete secret db-user-pass` (docs:tasks/configmap-secret/managing-secret-using-kubectl.md)
- Decode a Secret: `kubectl get secret secret-tiger-docker -o jsonpath='{.data.*}' | base64 -d` (docs:concepts/configuration/secret.md)
- Render generated ConfigMaps/Secrets: `kubectl kustomize ./` (docs:tasks/manage-kubernetes-objects/kustomization.md)

## Decision Tables

ConfigMap vs Secret:

| Aspect | ConfigMap | Secret |
|---|---|---|
| Purpose | Non-sensitive configuration | Sensitive data (credentials, keys) |
| Data format | Plain text / `binaryData` base64 | base64 `data`, plaintext `stringData` |
| Default storage | Plaintext in etcd | Plaintext in etcd (not encrypted at rest) |
| 1 MiB limit | Yes | Yes |
| Use for | env, files, command args | imagePullSecrets, TLS, basic-auth, ssh-auth |

## Version Notes

- `immutable` field for ConfigMaps/Secrets available since v1.19 (docs:concepts/configuration/configmap.md).
- v1.36 GA: "CSI driver opt-in for service account tokens via secrets field" (KEP-5538) and external ServiceAccount token signing (KEP-740) are stable; relevant for advanced secret patterns, not day-to-day authoring (blog:_posts/2026/kubernetes-v1-36-release/index.md).
- **FUTURE (v1.37)**: Static Pods referencing Secrets/ConfigMaps becomes invalid (`configMapRef`/`secretRef` in static pod manifests rejected) (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md).

## Pitfalls

- `stringData` + server-side apply conflicts: prefer `data` for SSA-managed manifests (docs:concepts/configuration/secret.md).
- Secrets are not encrypted at rest by default — do not store credentials in plaintext manifests or expect secrecy from base64 (docs:concepts/configuration/secret.md).
- Missing non-optional ConfigMap/Secret reference prevents Pod start; kubelet retries and emits Events while the object is unavailable (docs:tasks/configure-pod-container/configure-pod-configmap.md; docs:concepts/configuration/secret.md).
- ConfigMap/Secret data >1 MiB is rejected — use a volume or external store for large config (docs:concepts/configuration/configmap.md).
- `envFrom` key collisions silently drop conflicting keys instead of failing the Pod (docs:tasks/configure-pod-container/configure-pod-configmap.md).
- Changing an immutable ConfigMap/Secret requires creating a new object with a new name and updating references (docs:concepts/configuration/configmap.md).

## Cross-References

- For Kustomize generation of ConfigMaps/Secrets: `features/manifests.md`
- For imagePullSecrets and app-level secret handling: `features/security.md`
- For workload env wiring patterns: `features/workloads.md`

## Doc Refs

- docs:concepts/configuration/configmap.md
- docs:concepts/configuration/secret.md
- docs:tasks/configure-pod-container/configure-pod-configmap.md
- docs:tasks/inject-data-application/distribute-credentials-secure.md
- docs:tasks/configmap-secret/managing-secret-using-kubectl.md
- docs:tasks/manage-kubernetes-objects/kustomization.md
- docs:tasks/inject-data-application/environment-variable-expose-pod-information.md
- docs:tasks/configure-pod-container/configure-projected-volume-storage.md
