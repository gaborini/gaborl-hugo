+++
title = "Apache2 Reverse Proxy for Legacy Apps: A Migration Retrospective"
date = 2024-04-03T09:00:00-05:00
slug = "apache2-reverse-proxy-for-legacy-apps-a-migration-retrospective"
tags = ["apache", "reverse-proxy", "linux", "legacy-systems", "operations"]
categories = ["DevOps", "Web"]
metadescription = "A detailed retrospective on using Apache2 as a reverse proxy in front of legacy internal applications with TLS, auth, and rollout control."
metakeywords = "apache reverse proxy legacy app, apache vhost hardening, mod_proxy production"
+++

I had inherited two legacy internal applications that could not be rewritten quickly, but still needed modern ingress behavior: TLS termination, tighter headers, and controlled exposure. In 2024, I used Apache2 as the edge reverse proxy because the backends already depended on Apache semantics and I wanted minimal migration risk.

![Pexels stock photo: data center racks](/images/posts/infrastructure/apache-reverse-proxy-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 5408005](https://images.pexels.com/photos/5408005/pexels-photo-5408005.jpeg).* 

## Why Apache instead of replacing it immediately

In theory, replacing everything with a new stack sounded cleaner. In practice, I had tight constraints:

- one app depended on old auth behavior in `.htaccess`,
- the team had operational experience with Apache logs and modules,
- we needed stability first, modernization second.

So I chose a phased pattern: keep Apache, harden and standardize it, then decouple services over time.

## Initial architecture

Before the migration:

- clients hit legacy backends directly,
- TLS posture differed per application,
- headers and timeout behavior were inconsistent,
- incident debugging took too long.

After migration:

- edge Apache handled TLS, redirects, and headers,
- backend apps sat on private ports,
- centralized logging captured request correlation IDs,
- one deployment runbook covered both services.

## Base Apache module set

I removed most default modules and kept only what the pattern required:

```bash
sudo a2dismod autoindex status userdir
sudo a2enmod ssl headers proxy proxy_http rewrite remoteip http2
sudo systemctl restart apache2
```

Module hygiene reduced confusion. If a module was not actively needed, it stayed disabled.

## Virtual host template I standardized

```apache
<VirtualHost *:443>
    ServerName apps.gaborl.hu

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/apps.gaborl.hu/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/apps.gaborl.hu/privkey.pem

    Protocols h2 http/1.1
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Request-ID "%{UNIQUE_ID}e"

    ProxyPreserveHost On
    ProxyPass /legacy-a http://127.0.0.1:9001/ retry=0 timeout=30
    ProxyPassReverse /legacy-a http://127.0.0.1:9001/

    ProxyPass /legacy-b http://127.0.0.1:9002/ retry=0 timeout=30
    ProxyPassReverse /legacy-b http://127.0.0.1:9002/

    ErrorLog ${APACHE_LOG_DIR}/apps-error.log
    CustomLog ${APACHE_LOG_DIR}/apps-access.log combined
</VirtualHost>
```

I intentionally kept the proxy behavior explicit per path. Hidden rewrites had caused too many surprises in the old setup.

## TLS and certificate handling

I used Let's Encrypt with a scripted renewal check, then reloaded Apache only after certificate validation.

```bash
#!/usr/bin/env bash
set -euo pipefail
certbot renew --quiet
apachectl -t
systemctl reload apache2
```

This eliminated the old "renewed cert but forgot reload" incident type.

## Timeouts and upstream behavior

Legacy apps occasionally froze. I hardened timeout behavior so one bad upstream would not drag down the whole edge.

```apache
ProxyTimeout 30
Timeout 60
RequestReadTimeout header=20-40,MinRate=500 body=20,MinRate=500
```

I also returned a friendly maintenance/error page for known failure modes instead of raw upstream errors.

## Access control and segmented exposure

Not every endpoint needed public internet access. I segmented by location block and source IP.

```apache
<Location "/legacy-b/admin">
    Require ip 10.0.0.0/8 192.168.0.0/16
</Location>
```

For one client portal route, I added basic auth as a temporary compensating control while SSO work remained pending.

## Logging and observability improvements

I introduced a richer log format with forwarded client IP and request IDs.

```apache
LogFormat "%a %l %u %t \"%r\" %>s %b reqid=%{UNIQUE_ID}e fwd=%{X-Forwarded-For}i rt=%D" edge
CustomLog ${APACHE_LOG_DIR}/apps-edge.log edge
```

During postmortems, this single change reduced triage time significantly.

## Incident that validated the design

In week three, one backend process entered a crash loop due to malformed uploads. The edge layer continued serving the other application and returned stable 502 responses only for the failing path. Because of request IDs and isolated proxy routes, I traced the issue in minutes instead of hours.

What fixed it:

- capped upload size in Apache,
- tightened backend input validation,
- added crash-loop alert thresholding.

## Performance impact

I expected overhead from adding a proxy tier. In reality, user-perceived latency improved because TLS and connection handling became consistent.

Measured in my synthetic tests:

- P95 request latency dropped from 640ms to 410ms,
- TLS handshake failures dropped to near zero,
- error budget burn became predictable.

## Lessons learned

Apache worked well because I treated it as a disciplined edge router, not as a dumping ground for ad-hoc rewrites.

The key decisions that held up:

- minimal module set,
- explicit per-path proxy config,
- strict headers and timeout strategy,
- log design for incident response.

## What I planned next

After stabilizing this stack, my roadmap was:

1. move one backend to containerized service deployment,
2. keep Apache for compatibility routes,
3. gradually front new services with Traefik/Kubernetes ingress.

That gave me migration momentum without forcing a high-risk all-at-once rewrite.
