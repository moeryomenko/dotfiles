# Services & Networking — Service types, Ingress, Gateway API, DNS, app NetworkPolicies

> Expose apps through Services and Ingress/Gateway API, rely on cluster DNS for discovery, and isolate traffic with NetworkPolicies that allow DNS egress.

## Rules

1. Choose a Service type from `ClusterIP` (default), `NodePort`, `LoadBalancer`, `ExternalName`; the types build on each other. Why: NodePort implies ClusterIP and LoadBalancer builds on NodePort unless LB NodePort allocation is disabled.
2. Use `clusterIP: "None"` for a headless Service. Why: headless Services return per-Pod DNS records instead of a stable VIP.
3. Keep the default NodePort range 30000-32767 (static band 30000-30085, dynamic band 30086-32767). Why: the split reduces port collisions between static and dynamic allocations.
4. Give multi-port Services named ports; `targetPort` defaults to `port`. Why: EndpointSlices map traffic by name when a Service has several ports.
5. Provide a selector for EndpointSlice management; a selector-less Service gets no EndpointSlices and black-holes traffic until you create them manually (or use ExternalName). Why: the controller only generates EndpointSlices from matching Pods.
6. Do not rely on the core/v1 `Endpoints` API (deprecated since v1.33); use `discovery.k8s.io/v1` EndpointSlices. Why: EndpointSlices scale better and are the stable replacement.
7. Avoid `.spec.externalIPs` (deprecated in v1.36; removal planned v1.43); Kubernetes does not manage its allocation. Why: externalIPs were a CVE-2020-8554 footgun and are being removed.
8. Avoid `.spec.loadBalancerIP` (deprecated since v1.24). Why: cloud providers moved to annotations and `loadBalancerSourceRanges`.
9. Set `internalTrafficPolicy: Local` only for node-local routing; the default `Cluster` routes to all endpoints. Why: Local avoids extra hops at the cost of reaching only same-node endpoints.
10. Use `trafficDistribution` `PreferSameZone` or `PreferSameNode`; `PreferClose` is deprecated (v1.34) and an alias of `PreferSameZone`. Why: trafficDistribution expresses locality preference declaratively.
11. Ingress (networking.k8s.io/v1) requires an Ingress controller; set `pathType` per path (`ImplementationSpecific`, `Exact`, `Prefix`), prefer a default IngressClass, and `.spec.defaultBackend` is required when no rules exist. Why: missing `pathType` fails validation.
12. Prefer Gateway API for new greenfield work: four stable kinds (GatewayClass, Gateway, HTTPRoute, GRPCRoute), role-oriented, and the documented successor to Ingress; install its CRDs from the Gateway API project (third-party). Why: Gateway API adds header-based matching and traffic weighting that Ingress lacks.
13. Cluster DNS: `cluster.local` by default; Service A records are `my-svc.my-ns.svc.cluster.local`; headless Services get per-Pod A records; SRV records are `_port-name._port-protocol.my-svc.my-ns.svc.cluster.local`. Why: DNS names are the primary in-cluster discovery mechanism.
14. Use Pod `hostname`/`subdomain` fields to control Pod FQDN (`foo.bar.my-ns.svc.cluster.local`). Why: per-Pod hostnames need the subdomain to join the Service DNS namespace.
15. NetworkPolicy (networking.k8s.io/v1) isolation is opt-in per direction (`policyTypes` defaults to `Ingress`, plus `Egress` if egress rules exist) and policies are additive (union). Why: no policy means allow-all; policies only add restrictions.
16. An empty `podSelector` selects all Pods in the namespace; selectors combine `podSelector`, `namespaceSelector`, and `ipBlock`. Why: empty selectors are the standard default-deny building block.
17. A default-deny-egress policy also blocks DNS — add an egress rule for the cluster DNS Service (kube-system). Why: DNS traffic is egress like any other.
18. `endPort` range targeting is stable since v1.25 but requires a CNI that implements it; unsupported plugins apply only the single `port`. Why: enforcement depends on the CNI.
19. NetworkPolicy semantics: entries inside one `from` item are ANDed; separate `- from:` list items are ORed. Why: YAML indentation mistakes silently change policy meaning.
20. `hostNetwork` Pods' policy behavior is implementation-defined, and namespaces can be targeted via the immutable `kubernetes.io/metadata.name` label. Why: the label makes namespace identity stable for selectors.

## Good / Bad Examples

Good (selector-based Service):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-svc
spec:
  selector:
    app.kubernetes.io/name: myapp
  ports:
    - name: http
      port: 80
      targetPort: 8080
```
Bad (deprecated field and unnamed multi-port):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-svc
spec:
  externalIPs:          # deprecated in v1.36; removal planned v1.43
    - 203.0.113.10
  ports:
    - port: 80
    - port: 443          # multi-port Services require named ports
```

Good (Ingress with pathType):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-svc
                port:
                  number: 80
```
Bad:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            backend:            # missing pathType; legacy backend form
              serviceName: my-svc
              servicePort: 80
```

Good (default-deny egress with DNS allowed):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - port: 53
          protocol: UDP
```
Bad:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress     # no DNS rule -> workloads lose name resolution
```

## Command Recipes

- Inspect Services and endpoints: `kubectl get services`, `kubectl get endpointslices`, `kubectl describe service <name>` (docs:concepts/services-networking/service.md)
- Inspect Ingress: `kubectl get ingress`, `kubectl describe ingress ingress-resource-backend` (docs:concepts/services-networking/ingress.md)
- Label a namespace for NetworkPolicy namespaceSelector: `kubectl label namespace frontend namespace=frontend` (docs:concepts/services-networking/network-policies.md)
- Inspect kube-proxy mode (ipvs deprecation check): `kubectl -n kube-system get configmap kube-proxy -o jsonpath='{.data.config\.conf}' | grep 'mode:'` (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md)

## Decision Tables

Service type choice:

| Service type | Use when | Traffic delivery |
|---|---|---|
| ClusterIP (default) | In-cluster-only access | Stable VIP inside cluster |
| NodePort | Simple external access / tests | Node port on every node (30000-32767) |
| LoadBalancer | Cloud/on-prem LB fronting | Cloud LB -> NodePort -> Pods |
| ExternalName | Alias an external DNS name | CNAME-style, no proxying |

## Version Notes

- Endpoints API deprecated since v1.33; use EndpointSlices (docs:concepts/services-networking/service.md).
- `.spec.loadBalancerIP` on Service deprecated since v1.24 (docs:concepts/services-networking/service.md).
- `PreferClose` traffic distribution deprecated in v1.34 in favor of `PreferSameZone`/`PreferSameNode` (docs:concepts/services-networking/service.md).
- `externalIPs` deprecated in v1.36; removal planned v1.43 (docs:concepts/services-networking/service.md; blog:_posts/2026/kubernetes-v1-36-release/index.md).
- `StrictIPCIDRValidation` (tighter IP/CIDR validation on Services, Pods, NetworkPolicies): beta, enabled by default since v1.36 (blog:_posts/2026/kubernetes-v1-36-release/index.md).
- **FUTURE (v1.37)**: kube-proxy `ipvs` mode deprecation announced — disabled by default expected by v1.40, removal expected v1.43; startup warning already logged (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md).

## Pitfalls

- Missing `pathType` fails validation; a wrong `pathType` (e.g. `Prefix` vs `Exact`) silently changes routing semantics (docs:concepts/services-networking/ingress.md).
- NetworkPolicy `from` array AND/OR semantics are indentation-sensitive; verify with `kubectl describe` (docs:concepts/services-networking/network-policies.md).
- Deny-all egress blocks CoreDNS — workloads lose name resolution unless DNS egress is allowed (docs:concepts/services-networking/network-policies.md).
- NetworkPolicy `endPort` requires a CNI that supports it; unsupported plugins apply only the single `port` (docs:concepts/services-networking/network-policies.md).
- `kubectl port-forward` is TCP-only (docs:tasks/access-application-cluster/port-forward-access-application-cluster.md).
- A selector-less Service never gets EndpointSlices — traffic to it black-holes until you create them manually (docs:concepts/services-networking/service.md).
- Ingress NGINX was retired March 24, 2026 (no more releases/security fixes); existing deployments keep working (blog:_posts/2026/kubernetes-v1-36-release/index.md).

## Cross-References

- For app-level NetworkPolicy details and DNS egress: `features/security.md`
- For selector/label authoring and Ingress pathType in manifests: `features/manifests.md`
- For debugging connectivity with port-forward: `features/debugging.md`
- For cluster-level networking (CNI, kube-proxy, connectivity troubleshooting): `../kubernetes-admin/features/networking.md`

## Doc Refs

- docs:concepts/services-networking/service.md
- docs:concepts/services-networking/ingress.md
- docs:concepts/services-networking/gateway.md
- docs:concepts/services-networking/network-policies.md
- docs:concepts/services-networking/dns-pod-service.md
- docs:concepts/services-networking/endpoint-slices.md
- docs:concepts/services-networking/service-traffic-policy.md
- docs:tasks/access-application-cluster/port-forward-access-application-cluster.md
- blog:_posts/2026/deprecation-of-service-externalips.md
