+++
title = "WireGuard Site-to-Site Retrospective: Secure Connectivity Without the Usual Pain"
date = 2024-01-10T09:00:00-05:00
slug = "wireguard-site-to-site-retrospective-secure-connectivity-without-the-usual-pain"
tags = ["wireguard", "vpn", "networking", "linux", "security"]
categories = ["Networking", "Linux"]
metadescription = "A practical retrospective on building a reliable WireGuard site-to-site VPN between home lab and VPS environments with routing, MTU, and operational hardening lessons."
metakeywords = "wireguard site to site setup, wireguard mtu tuning, linux vpn operations"
+++

At the beginning of 2024, I replaced a fragile VPN setup with WireGuard for site-to-site connectivity between my homelab and VPS network. The migration looked simple on paper, but reliability required more than just generating keys and bringing interfaces up.

![Pexels stock photo: network cabling](/images/posts/infrastructure/wireguard-vpn-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 2881229](https://images.pexels.com/photos/2881229/pexels-photo-2881229.jpeg).* 

## What I needed from the tunnel

The design goals were practical:

- stable private connectivity for services and backups,
- minimal operational overhead,
- deterministic fail behavior,
- enough throughput for nightly sync jobs,
- tight network exposure boundaries.

I did not need a full mesh with dynamic control plane. I needed a dependable, understandable tunnel.

## Topology choice

I built a hub-and-spoke model:

- VPS edge node as hub,
- homelab gateway as spoke,
- optional mobile admin peer with restricted routes.

This kept routing policy centralized while limiting blast radius.

## Baseline config pattern

On each peer, I used small explicit configs with strict `AllowedIPs`.

```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 10.90.0.2/24
PrivateKey = <private-key>
ListenPort = 51820

[Peer]
PublicKey = <hub-public-key>
Endpoint = vpn.gaborl.hu:51820
AllowedIPs = 10.90.0.0/24, 10.20.0.0/24
PersistentKeepalive = 25
```

Limiting `AllowedIPs` reduced accidental route leaks and simplified troubleshooting.

## Routing and firewall integration

The tunnel only solved encryption. I still needed routing and filtering discipline.

I used:

- policy-based routing for selected internal networks,
- explicit `nftables` rules for tunnel ingress/egress,
- default-drop policy with tightly scoped accept rules.

This prevented the common mistake of "VPN is up, but policy is unclear."

## MTU tuning lessons

My first rollout had intermittent packet loss on large transfers. Root cause was MTU mismatch across uplink path.

I fixed it by:

- testing path MTU explicitly,
- lowering WireGuard interface MTU,
- validating throughput and retransmit behavior under load.

After tuning, transfer stability improved immediately.

## Key rotation and peer lifecycle

I documented peer lifecycle with clear states:

- provisioned,
- active,
- paused,
- revoked.

Key rotation happened quarterly for critical peers. Revoked peers were removed from config and firewall allowlists in the same change window.

## Observability and health checks

I exposed tunnel health via:

- handshake age monitoring,
- peer transfer counters,
- packet error trend tracking,
- route reachability probes.

One simple alert on stale handshake age caught most real outages quickly.

## Incident that shaped the final setup

A home ISP endpoint IP change broke connectivity at 03:00. The tunnel did not recover automatically because DNS caching on one node was stale.

Fixes:

- lowered DNS TTL for tunnel endpoint,
- added periodic endpoint re-resolution,
- created auto-remediation script for stale peer endpoint.

This made future endpoint changes effectively non-events.

## Security hardening changes

I added:

- narrow management access only over VPN,
- per-peer route restrictions,
- split admin and service peers,
- audit logging for firewall and route changes.

I also removed legacy SSH exposure from public interfaces wherever VPN access was sufficient.

## Outcomes after rollout

- tunnel uptime improved significantly,
- backup job success rate increased,
- remote maintenance became predictable,
- incident resolution time dropped because visibility was better.

The highest-value gain was confidence during off-hours maintenance.

## Mistakes to avoid

1. Over-broad `AllowedIPs` that hide route mistakes.
2. Ignoring MTU path behavior.
3. Treating key management as one-time setup.
4. Running tunnel without basic health metrics.
5. Mixing admin and service traffic without policy boundaries.

## Final takeaway

WireGuard was fast to deploy, but reliability came from network discipline around it: routing, firewall policy, key lifecycle, and observability. Once those were in place, secure connectivity became boring and dependable, which was exactly the goal.
