+++
title = "Nginx Edge Caching and Zero-Downtime Deployments: What Actually Worked"
date = 2024-03-27T09:00:00-05:00
slug = "nginx-edge-caching-and-zero-downtime-deployments-what-actually-worked"
tags = ["nginx", "caching", "deployment", "linux", "performance"]
categories = ["DevOps", "Web"]
metadescription = "A long practical report on setting up Nginx edge caching and predictable zero-downtime deployments on a small VPS stack."
metakeywords = "nginx edge cache config, zero downtime nginx deploy, stale cache nginx"
+++

In early 2024, I rebuilt my Nginx edge layer after too many fragile deploy nights. The objective was not theoretical elegance. I wanted predictable deploys, controlled cache behavior, and safer failure handling under real traffic spikes.

![Pexels stock photo: server hardware close-up](/images/posts/infrastructure/nginx-edge-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 5050305](https://images.pexels.com/photos/5050305/pexels-photo-5050305.jpeg).* 

## Baseline problems I needed to solve

The old setup had three recurring issues:

- deploy windows caused brief 502 bursts,
- cache keys were too broad and sometimes served wrong variants,
- backend slowdowns propagated directly to users.

The stack was "fast on good days" but inconsistent on bad days.

## Target design

I split responsibilities clearly:

- Nginx handled TLS, static asset caching, and stale-on-error behavior,
- app service handled dynamic rendering,
- deploy pipeline switched release symlink atomically,
- systemd ensured process supervision and graceful termination.

## Core Nginx cache configuration

```nginx
proxy_cache_path /var/cache/nginx/edge levels=1:2 keys_zone=edge_cache:200m max_size=10g inactive=60m use_temp_path=off;

map $http_accept_encoding $cache_bypass_encoding {
    default 0;
    ""      1;
}

server {
    listen 443 ssl http2;
    server_name gaborl.hu;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_cache edge_cache;
        proxy_cache_key "$scheme$request_method$host$request_uri";
        proxy_cache_valid 200 10m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504 updating;
        proxy_cache_background_update on;

        add_header X-Cache-Status $upstream_cache_status always;

        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

The critical part was `proxy_cache_use_stale`. It turned backend incidents from immediate user pain into manageable alert windows.

## Cache key and invalidation strategy

I avoided fancy cache key logic and used predictable keys with explicit bypass routes:

- static content had long TTL,
- dashboard/admin paths bypassed cache,
- deploy webhooks triggered selective purge for landing and docs pages.

I tested purge behavior with a script before every release. Without that, stale-content incidents were easy to reintroduce.

## Zero-downtime deploy method

I used release directories and a stable symlink:

```bash
/opt/apps/myapp/releases/2024-03-27_1930
/opt/apps/myapp/current -> /opt/apps/myapp/releases/2024-03-27_1930
```

Deploy steps were:

1. build and upload release,
2. run health checks against release-specific port,
3. atomically switch `current` symlink,
4. reload app process,
5. run post-switch smoke tests,
6. keep previous release for rollback.

Rollback took under 30 seconds because it was just a symlink switch + process restart.

## Nginx reload safety

I treated every Nginx reload as a potential outage and used strict validation.

```bash
nginx -t
systemctl reload nginx
```

I also added a pre-deploy gate that failed the pipeline if config linting failed. That removed human luck from the loop.

## TLS and transport tuning

I standardized TLS policy and connection behavior:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
keepalive_timeout 65;
client_max_body_size 20m;
```

I had initially set aggressive keepalive values that caused churn under mobile networks. Increasing timeout reduced handshake pressure.

## Observability that mattered

I added metrics and logs focused on operational outcomes:

- cache hit ratio,
- upstream response time histograms,
- 502/504 error rates per route,
- deploy window error deltas.

The most useful dashboard panel was cache hit ratio by route group, because it immediately showed accidental cache bypasses.

## Incident review: backend timeout storm

One evening, a database lock issue caused upstream timeouts. Before this redesign, that would have been a full user-facing incident. With stale-on-error enabled, many routes served cached responses while the app recovered.

Outcome:

- user-visible error rate stayed below 2 percent,
- ops had enough time to fix DB lock contention,
- no emergency rollback was needed.

That incident alone justified the redesign effort.

## Performance and stability after rollout

After six weeks:

- P95 latency improved from 480ms to 290ms,
- cache hit ratio stabilized between 68-77 percent,
- deploy-related 5xx spikes were effectively eliminated,
- rollback confidence increased because procedure was boring and tested.

## Mistakes I corrected

I made two notable mistakes early:

- cache TTL too long on one frequently updated changelog page,
- missing bypass on one authenticated endpoint.

Both were fixed with explicit route rules and automated cache-behavior tests in CI.

## Final operating principles

I kept these principles documented in my runbook:

1. Optimize for predictable failure behavior, not benchmark screenshots.
2. Keep cache rules explicit per route class.
3. Treat config lint + smoke checks as mandatory deploy gates.
4. Keep rollback mechanically simple.
5. Measure real user-facing outcomes after every change.

That turned Nginx from "fast when lucky" into a reliable edge system I trusted during real incidents.
