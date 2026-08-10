---
name: kubernetes-developer
description: Kubernetes application development skill — Deployment/StatefulSet manifests, Services, ConfigMaps/Secrets, probes, Helm charts, deployment strategies, and debugging applications. Load automatically for manifest-authoring tasks.
invocation_policy: automatic
---

# Kubernetes Developer Skill Assembly

Unified Kubernetes application-development knowledge base organized by domain features. Route to the correct feature file based on the task. All content targets Kubernetes v1.36 (GA); v1.37 items appear only as labeled **FUTURE** callouts.

## Configuration

The kubernetes-developer skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Manifests
When authoring or reviewing manifests, labels/annotations, selectors, or Kustomize overlays:
1. Load `features/manifests.md` for manifest authoring, labels/annotations, kustomize, and YAML conventions

### Workloads
When creating or debugging Pods, Deployments, StatefulSets, DaemonSets, Jobs/CronJobs:
1. Load `features/workloads.md` for workload controllers, pod lifecycle, and container restart rules

### Services & Networking
When exposing applications with Services, Ingress, Gateway API, DNS, or app NetworkPolicies:
1. Load `features/services-networking.md` for Service types, Ingress, Gateway API, DNS, and app-side NetworkPolicies

### Config & Secrets
When wiring ConfigMaps/Secrets into workloads, environment variables, or immutable config:
1. Load `features/config-secrets.md` for ConfigMaps, Secrets, env wiring, immutable config, and 12-factor patterns

### Resources & Probes
When setting requests/limits, QoS classes, or liveness/readiness/startup probes:
1. Load `features/resources-probes.md` for requests/limits, QoS classes, and liveness/readiness/startup probes

### Deployment Strategies
When planning rolling updates, canary/blue-green, rollback, or progressive delivery:
1. Load `features/deployment-strategies.md` for rolling updates, canary/blue-green, rollback, and progressive delivery

### API Migrations
When migrating manifests off deprecated APIs or bumping API group versions:
1. Load `features/api-migrations.md` for the v1.36 deprecation/removal tables and manifest-level migration guidance

### Debugging
When debugging applications with logs, exec, port-forward, ephemeral containers, or local clusters:
1. Load `features/debugging.md` for kubectl logs/exec/port-forward, kubectl debug, ephemeral containers, and local dev (kind)

### Helm
When authoring Helm charts, templating, designing values, or choosing Helm vs Kustomize:
1. Load `features/helm.md` for chart authoring, templating, values design, and Helm vs Kustomize

### Security
When hardening application manifests against Pod Security Standards or handling images/secrets:
1. Load `features/security.md` for app-level PSA compliance, seccomp, runAsNonRoot, image/secret handling, and app NetworkPolicies

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics; within-skill references use bare feature names. Cross-skill references to the kubernetes-admin skill use relative paths from this skill's root directory and appear in the feature files.
