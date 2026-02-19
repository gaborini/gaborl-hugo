+++
title = "Kubernetes in a Homelab: Lessons from My k3s Cluster"
date = 2024-03-11T09:00:00-05:00
slug = "kubernetes-in-a-homelab-lessons-from-my-k3s-cluster"
tags = ["kubernetes", "k3s", "containers", "devops", "gitops"]
categories = ["DevOps", "Kubernetes"]
metadescription = "A detailed retrospective on building and operating a small k3s Kubernetes cluster in a homelab, including networking, storage, and reliability lessons."
metakeywords = "k3s homelab guide, kubernetes lessons learned, kubernetes backup and ingress"
+++

I had postponed Kubernetes for a long time because my Docker-based setup already worked. In 2024, I finally migrated core workloads to a small k3s cluster to learn platform operations in a realistic but controlled environment. This article summarizes what I built, what failed, and what actually improved.

![Pexels stock photo: container yard from above](/images/posts/infrastructure/kubernetes-containers-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 35627339](https://images.pexels.com/photos/35627339/pexels-photo-35627339.jpeg).* 

## Cluster scope and constraints

I ran a three-node k3s cluster:

- 1 control-plane node,
- 2 worker nodes,
- all on low-power mini PCs.

Constraints were real:

- limited RAM,
- mixed SSD quality,
- home uplink and occasional power interruptions.

That made it a good training ground for resilient design choices.

## Why k3s

I chose k3s because:

- install and upgrade path was lighter than full kubeadm for this use case,
- resource overhead was lower,
- operational complexity stayed manageable while still teaching core Kubernetes patterns.

## Workload classes I migrated

I moved services in phases:

1. stateless web tools,
2. internal APIs,
3. selected stateful services with backups,
4. observability stack.

I delayed databases until I had storage and restore behavior tested.

## Namespace and policy structure

I grouped workloads by trust and lifecycle:

- `platform`: ingress, cert-manager, DNS tooling,
- `apps`: user-facing services,
- `ops`: Prometheus, Grafana, Loki,
- `sandbox`: experiments and temporary tests.

I enforced resource requests/limits and quotas early. This prevented one noisy test workload from starving others.

## Ingress and certificate flow

I initially used Traefik (bundled with k3s), then standardized ingress rules and cert-manager issuance for cleaner certificate lifecycle.

Example ingress pattern:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: docs
  namespace: apps
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - docs.gaborl.hu
      secretName: docs-tls
  rules:
    - host: docs.gaborl.hu
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: docs
                port:
                  number: 3000
```

This gave me repeatable routing and certificate management as code.

## Storage reality check

Persistent storage was the hardest part. My first attempt used local-path volumes too broadly. It worked until I needed predictable rescheduling after a node issue.

I adjusted by:

- keeping most stateful data pinned to specific nodes intentionally,
- adding clear backup jobs with restore tests,
- documenting which workloads were allowed to be stateful in cluster.

I avoided pretending the homelab was a cloud-grade storage platform.

## GitOps workflow

I moved manifests into Git and applied changes via pull requests + automation.

Benefits I got immediately:

- diffable infra changes,
- easier rollback via git revert,
- fewer "mystery kubectl edits".

I still used emergency `kubectl` in incidents, but always reconciled back into Git right after.

## Reliability incidents and fixes

### Incident 1: node reboot storm

A flaky power strip rebooted two nodes close together. The cluster survived, but a few pods took too long to settle because readiness probes were too optimistic.

Fixes:

- tightened readiness/liveness probes,
- increased startup probe windows for slow apps,
- added staged node reboot procedure.

### Incident 2: resource contention

One analytics job consumed too much memory and evicted unrelated pods.

Fixes:

- stricter memory limits,
- dedicated node affinity for bursty jobs,
- alerting on memory pressure before eviction cascades.

## Security posture improvements

I made incremental but meaningful security changes:

- disabled default service account usage where unnecessary,
- applied network policies for sensitive namespaces,
- used sealed secrets for environment config,
- rotated tokens and reviewed RBAC monthly.

RBAC drift had been easy to miss before I scheduled periodic reviews.

## Backup and restore drills

I scheduled and tested:

- etcd snapshots,
- namespace-level manifest exports,
- volume backups for selected stateful apps.

The restore drills exposed weak assumptions fast. One app came back with stale credentials because I had not versioned its secret rotation process correctly.

## Performance and ops outcomes

After two months, I measured these practical outcomes:

- faster repeatable deployment workflows,
- fewer manual ingress mistakes,
- better visibility into resource usage,
- improved confidence when patching host systems.

I did not magically eliminate outages. I reduced ambiguity during outages.

## What I would do differently next time

If I rebuilt today, I would:

1. establish stricter workload admission rules from day one,
2. separate stateful and stateless clusters earlier,
3. automate node conformance checks after upgrades,
4. define SLOs per service before migration.

## Closing perspective

Kubernetes in a homelab was not about hype. It was a structured way to learn platform engineering under constraints. The biggest gain was operational discipline: clear ownership, codified changes, and tested recovery paths.

That discipline carried over to every non-Kubernetes project afterward.
