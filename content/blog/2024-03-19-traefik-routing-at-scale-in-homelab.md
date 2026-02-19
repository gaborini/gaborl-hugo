+++
title = "Traefik Routing at Scale in a Homelab: What Broke and What Held"
date = 2024-03-19T09:00:00-05:00
slug = "traefik-routing-at-scale-in-homelab-what-broke-and-what-held"
tags = ["traefik", "docker", "reverse-proxy", "devops", "routing"]
categories = ["DevOps", "Containers"]
metadescription = "A deep retrospective on running Traefik for many self-hosted services with dynamic routing, middleware policy, and safer operations."
metakeywords = "traefik homelab setup, traefik middleware patterns, docker labels routing"
+++

When I crossed roughly twenty self-hosted services in my homelab, manual reverse-proxy configuration stopped scaling. In 2024, I moved most ingress to Traefik, and I learned quickly that dynamic routing helped a lot only when label discipline and middleware governance were strict.

![Pexels stock photo: network cabling](/images/posts/infrastructure/traefik-network-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 2881229](https://images.pexels.com/photos/2881229/pexels-photo-2881229.jpeg).* 

## Why I switched to Traefik

My previous stack had too many hand-written route blocks. Every new service created repetitive ingress work and higher chance of copy-paste mistakes.

I switched because I wanted:

- automatic service discovery from Docker labels,
- reusable middleware chains,
- built-in certificate automation,
- clearer separation between platform routing and app internals.

## Initial topology

I ran Traefik in Docker with two entrypoints:

- `web` for HTTP -> HTTPS redirects,
- `websecure` for TLS traffic.

Services joined one shared proxy network and exposed only internal ports. Public exposure existed only through Traefik routers.

## Static configuration

```yaml
# traefik.yml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: ops@gaborl.hu
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

api:
  dashboard: false

log:
  level: INFO
```

`exposedByDefault: false` was the most important line. It prevented accidental public exposure when someone forgot labels.

## Dynamic routing pattern

Each app had explicit router, service, and middleware labels.

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.docs.rule=Host(`docs.gaborl.hu`)"
  - "traefik.http.routers.docs.entrypoints=websecure"
  - "traefik.http.routers.docs.tls=true"
  - "traefik.http.routers.docs.tls.certresolver=letsencrypt"
  - "traefik.http.services.docs.loadbalancer.server.port=3000"
  - "traefik.http.routers.docs.middlewares=secure-headers@file,rate-limit@file"
```

I banned one-off middleware definitions inside random compose files. Shared policy lived centrally in file provider config.

## Middleware governance that saved me

I defined standard middleware bundles:

- security headers,
- compression,
- rate limiting,
- auth for internal tools.

```yaml
http:
  middlewares:
    secure-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        stsSeconds: 31536000
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
```

This prevented route drift where each service had slightly different protections.

## Certificate and DNS lessons

ACME mostly worked well, but I initially hit rate limits during repeated test redeploys. I fixed that by:

- using staging ACME endpoint for test stacks,
- protecting `acme.json` persistence,
- reducing unnecessary container churn.

I also versioned DNS records and proxy rules together in my infra repo to avoid mismatch incidents.

## Outage I caused (and fixed)

I introduced a wildcard redirect middleware that unintentionally applied to an API subdomain used by a webhook sender. Result: webhook retries exploded.

Fix steps:

1. split middleware chains by app class,
2. added explicit integration tests for critical webhook routes,
3. made redirect policy opt-in instead of global.

That incident changed my approach from convenience-first to blast-radius-first.

## Multi-environment layout

I eventually split routing domains into:

- public services,
- internal admin tools,
- experimental services.

Each class had its own middlewares and stricter default policy. Experimental services were never allowed to inherit public policy automatically.

## Metrics and observability

I enabled Traefik metrics and logged route-level errors to my central stack. The metrics that mattered most:

- request rate by router,
- 4xx/5xx ratio by service,
- certificate renewal status,
- latency percentile drift after config changes.

With these dashboards, I could spot broken labels within minutes.

## Results after three months

- onboarding a new service dropped from ~30 minutes to under 10,
- ingress misconfig incidents decreased significantly,
- certificate renewals became routine,
- rollback complexity dropped because route policy was centralized.

## What I would keep as hard rules

1. Never expose by default.
2. Centralize middleware definitions.
3. Treat labels as code with review.
4. Separate public and internal route domains.
5. Test webhook/API routes after every proxy policy change.

Traefik made the platform far easier to operate, but only after I enforced policy discipline. Dynamic config without governance had created almost as much risk as manual config had.
