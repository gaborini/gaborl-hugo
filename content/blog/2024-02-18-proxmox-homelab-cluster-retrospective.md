+++
title = "Proxmox Homelab Cluster Retrospective: Stability Before Complexity"
date = 2024-02-18T09:00:00-05:00
slug = "proxmox-homelab-cluster-retrospective-stability-before-complexity"
tags = ["proxmox", "virtualization", "homelab", "linux", "devops"]
categories = ["DevOps", "Homelab"]
metadescription = "A long retrospective on building a reliable Proxmox homelab cluster with practical lessons on storage, backups, networking, and operations."
metakeywords = "proxmox cluster homelab guide, proxmox backup strategy, virtualization reliability"
+++

My old homelab virtualization setup had grown organically. It worked most of the time, but maintenance windows were stressful and recoveries were too manual. In 2024, I redesigned around a small Proxmox cluster with one principle: stability before cleverness.

![Pexels stock photo: server hardware in blue light](/images/posts/infrastructure/proxmox-cluster-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 17489163](https://images.pexels.com/photos/17489163/pexels-photo-17489163.jpeg).* 

## Cluster goals

I kept goals intentionally narrow:

- predictable VM lifecycle,
- fast rollback path,
- usable backup and restore flow,
- simple enough networking to debug quickly.

I avoided chasing enterprise-grade patterns that did not match my hardware limits.

## Hardware and role layout

The cluster used three nodes:

- node-a: primary workloads and automation,
- node-b: secondary workloads and failover target,
- node-c: lighter services plus quorum support.

I documented resource classes for each VM type so scheduling and expectations were explicit.

## Storage decisions that actually worked

I tested shared storage options but found complexity high for my budget and risk tolerance. I landed on:

- local NVMe for active VM disks,
- scheduled backups to dedicated backup storage,
- replication only for selected critical workloads.

This gave me simpler failure behavior. When a node failed, I restored or restarted from known-good backups instead of depending on fragile storage assumptions.

## Network segmentation model

I split traffic into VLAN-backed bridges:

- management,
- services,
- storage/backup,
- sandbox.

This reduced accidental cross-talk and made packet tracing easier during weird latency spikes.

## Template and image strategy

I standardized golden templates for Debian and Ubuntu guests with:

- hardened base config,
- cloud-init support,
- monitoring agent pre-installed,
- backup hooks enabled.

VM provisioning became a versioned workflow instead of click-driven improvisation.

## Backup discipline and restore drills

I used Proxmox Backup Server with tiered retention:

- daily snapshots for critical VMs,
- weekly for medium-priority VMs,
- monthly archives for low-change utility boxes.

Most importantly, I rehearsed restores monthly. The first drill exposed a missing post-restore DNS update step that had never been documented.

## HA expectations and reality

I intentionally did not market this setup to myself as "high availability" in the enterprise sense. On limited hardware, the better framing was:

- faster and safer recovery,
- reduced manual chaos,
- bounded downtime.

That mindset kept design decisions honest.

## Performance bottleneck I hit

In the first month, backup windows caused I/O contention on one node hosting both active services and backup-heavy workloads. Symptoms were latency spikes and occasional guest stalls.

Fixes:

- moved backup-heavy VMs to a different node,
- staggered backup start times,
- tuned compression and bandwidth limits.

After this, overnight backup impact dropped to acceptable levels.

## Operational playbooks

I added playbooks for:

- failed node reboot,
- corrupted guest disk recovery,
- runaway VM resource usage,
- planned cluster patching.

Each playbook included verification commands and rollback checkpoints.

## Upgrade and patching model

I switched from ad-hoc upgrades to phased maintenance:

1. patch one non-critical node,
2. run workload and network checks,
3. patch second node,
4. patch primary node last,
5. run post-maintenance smoke tests.

This sequence prevented platform-wide surprise regressions.

## Security hardening applied

I tightened:

- management network access control,
- API token scope,
- SSH key hygiene,
- audit logging retention.

The highest value change was separating daily operations credentials from high-privilege break-glass accounts.

## What improved after two months

- VM provisioning became consistent and faster,
- restore confidence increased significantly,
- change windows became routine instead of risky,
- incident timelines were shorter because topology was documented.

## Mistakes I would avoid next time

- trying too many storage experiments in the same month,
- underestimating backup I/O impact,
- leaving too many one-off VMs outside template discipline.

## Practical rules I now keep

1. Prefer reproducibility over feature novelty.
2. Test restores, do not just trust backup success logs.
3. Keep network segmentation simple and visible.
4. Patch in phases with clear stop points.
5. Document every manual recovery command used during incidents.

Proxmox gave me a stable foundation because I kept architecture conservative and operations disciplined. That was enough to support all the other lab services without turning platform maintenance into a second full-time job.
