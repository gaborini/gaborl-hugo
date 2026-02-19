+++
title = "Observability Stack Retrospective: Prometheus, Grafana, and Loki in Practice"
date = 2024-01-31T09:00:00-05:00
slug = "observability-stack-retrospective-prometheus-grafana-and-loki-in-practice"
tags = ["observability", "prometheus", "grafana", "loki", "devops"]
categories = ["DevOps", "Monitoring"]
metadescription = "A long-form retrospective on building an observability stack with Prometheus, Grafana, and Loki, focused on practical alerting and incident response."
metakeywords = "prometheus grafana loki setup, observability incident response, alert fatigue reduction"
+++

I used to think monitoring was mostly about dashboards. Incidents in late 2023 and early 2024 proved otherwise. The real value came from actionable signals, low-noise alerting, and clear triage flow. This retrospective covers how I rebuilt my stack around Prometheus, Grafana, and Loki.

![Pexels stock photo: operations in data center](/images/posts/infrastructure/observability-ops-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 1181354](https://images.pexels.com/photos/1181354/pexels-photo-1181354.jpeg).* 

## The problem before redesign

My original setup had plenty of charts but weak operational value:

- alert noise was high,
- label conventions were inconsistent,
- logs were not linked to request flow,
- on-call triage took too long.

Visibility existed, but clarity did not.

## Architecture I moved to

The revised stack had four clear layers:

- Prometheus for metrics and recording rules,
- Loki + promtail for structured logs,
- Grafana for dashboards and drill-down workflows,
- alert routing by severity and service ownership.

Every metric and log stream had to carry `env`, `service`, and `instance` labels.

## Metric design conventions

I standardized metric schema before creating new dashboards:

- consistent service prefixes,
- stable label sets,
- histogram buckets on latency-sensitive endpoints,
- explicit split between platform and business metrics.

This one change made queries and alert rules maintainable.

## Alerting model change

I shifted from threshold spam to SLO-oriented rules:

- alert on sustained user-impact conditions,
- separate warning and paging severity,
- include runbook link in every alert annotation,
- group related alerts to reduce duplicate pages.

Example 5xx burn-rate style rule:

```yaml
groups:
  - name: app-slo
    rules:
      - alert: HighErrorRateBurn
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.03
        for: 10m
        labels:
          severity: page
          service: web-edge
        annotations:
          summary: "High 5xx burn on web-edge"
          runbook: "https://ops.gaborl.hu/runbooks/web-edge-error-burn"
```

This reduced false urgency while still catching real degradation quickly.

## Logging improvements

I moved application logs to structured JSON and indexed key fields:

- request ID,
- route,
- status code,
- release version,
- error class.

This allowed a fast path from alert panel to exact failure traces.

## Dashboard strategy

For each critical service, I kept one compact "golden signals" dashboard:

- latency percentiles,
- traffic rate,
- error ratio,
- saturation (CPU, memory, queue depth).

If a panel did not influence operational decisions, I deleted it.

## Incident that validated the redesign

A deployment introduced route-specific 5xx spikes in one region. The alert fired with correct metadata, and I jumped from Grafana to Loki logs filtered by route and release label. I identified a bad config value and rolled back quickly.

The triage time was much shorter than with the old stack.

## Alert fatigue reduction steps

I made three specific changes:

1. removed alerts that had no clear operator action,
2. merged redundant host alerts into service-level signals,
3. added maintenance silence windows for planned operations.

Pager load decreased and page quality improved.

## Capacity and cost controls

I added recording rules and long-range reports for:

- log storage growth,
- scrape target cardinality,
- highest-cardinality labels,
- infrastructure cost trend by service.

Without cardinality control, observability itself becomes unstable and expensive.

## Outcomes after rollout

- faster root-cause identification,
- fewer irrelevant pages,
- clearer ownership during incidents,
- stronger postmortem evidence quality.

Most importantly, on-call confidence improved because signals became trustworthy.

## Rules I kept

1. Every alert must point to a runbook.
2. Every dashboard panel must answer an operational question.
3. Structured logging is mandatory for critical services.
4. Label cardinality is reviewed continuously.
5. Observability changes receive the same review rigor as application code.

## Closing thought

Observability became effective only after I treated it as an operational product, not as a graph collection. Once metrics, logs, alerts, and runbooks were aligned, incident response became much more predictable.
