+++
title = "PostgreSQL Performance Tuning Retrospective: From Slow Queries to Stable Latency"
date = 2024-01-17T09:00:00-05:00
slug = "postgresql-performance-tuning-retrospective-from-slow-queries-to-stable-latency"
tags = ["postgresql", "database", "performance", "linux", "devops"]
categories = ["Databases", "DevOps"]
metadescription = "A deep retrospective on tuning PostgreSQL performance with query analysis, index strategy, autovacuum adjustments, and connection management improvements."
metakeywords = "postgresql tuning guide, postgresql query performance, autovacuum optimization"
+++

In January 2024, my main PostgreSQL instance had no catastrophic failure, but latency and tail behavior were getting worse. Endpoint performance was inconsistent, and slow periods were hard to explain. This retrospective summarizes the tuning cycle that made query latency far more stable.

![Pexels stock photo: server hardware close-up](/images/posts/infrastructure/postgresql-tuning-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 5050305](https://images.pexels.com/photos/5050305/pexels-photo-5050305.jpeg).* 

## Baseline symptoms

The database showed:

- periodic spikes in P95 and P99 query latency,
- growing autovacuum lag on busy tables,
- occasional connection saturation,
- expensive sequential scans in critical paths.

No single parameter tweak could solve this. I needed an end-to-end tuning pass.

## Measurement before tuning

I started by improving observability first:

- enabled `pg_stat_statements`,
- logged slow queries with context,
- tracked bloat indicators and vacuum timing,
- monitored connection and lock wait behavior.

This avoided blind tuning based on anecdotes.

## Query-level optimization pass

I reviewed top offenders from `pg_stat_statements` and query logs. The biggest wins came from:

- adding missing composite indexes aligned to real predicates,
- rewriting one report query to reduce unnecessary joins,
- introducing keyset pagination where offset scans were expensive,
- reducing `SELECT *` patterns in high-frequency API calls.

Even small query changes had large tail-latency impact.

## Index strategy changes

I removed redundant indexes and added targeted ones.

```sql
CREATE INDEX CONCURRENTLY idx_orders_customer_created
ON orders (customer_id, created_at DESC);

CREATE INDEX CONCURRENTLY idx_events_tenant_status_created
ON events (tenant_id, status, created_at DESC);
```

Using `CONCURRENTLY` minimized locking impact during production hours.

## Autovacuum tuning

Autovacuum defaults were too passive for my write-heavy tables. I tuned at table-level for hot relations.

```sql
ALTER TABLE events SET (
  autovacuum_vacuum_scale_factor = 0.02,
  autovacuum_analyze_scale_factor = 0.01,
  autovacuum_vacuum_threshold = 5000
);
```

This reduced dead tuple accumulation and improved planner estimates.

## Memory and planner settings

I tuned with caution and measured each step:

- increased `shared_buffers` moderately,
- adjusted `work_mem` for query classes,
- tuned `effective_cache_size` to reflect host reality,
- validated planner behavior after each change.

I avoided aggressive global `work_mem` increases that could multiply under concurrency.

## Connection management

I introduced PgBouncer in transaction pooling mode to smooth spikes and reduce backend process pressure.

Results:

- fewer connection storms,
- more predictable backend utilization,
- lower lock contention during burst traffic.

This had outsized impact compared with raw parameter tuning alone.

## Incident that validated the changes

A weekly analytics job had previously caused severe API latency spikes. After query rewrites, index changes, and pooling, the same job still consumed resources but no longer destabilized online traffic.

That was the practical proof I needed.

## Maintenance improvements

I added regular maintenance and checks:

- scheduled `VACUUM (ANALYZE)` windows for key tables,
- index bloat review cadence,
- lock-wait alert thresholds,
- query regression review in release checklist.

Performance tuning became part of operations, not one-off firefighting.

## Metrics after tuning cycle

Over the following weeks:

- P95 latency improved significantly,
- P99 spikes became less frequent and shorter,
- autovacuum backlog reduced,
- CPU usage became more stable under peak traffic.

Most importantly, behavior became predictable enough to plan capacity.

## Mistakes I corrected

- adding too many indexes initially without usage validation,
- tuning parameters before measuring query behavior,
- ignoring connection pooling until late in the cycle.

Fixing these made later tuning more efficient.

## Rules I kept

1. Measure first, then tune.
2. Optimize top query offenders before touching many global knobs.
3. Treat autovacuum settings as workload-specific.
4. Use connection pooling to absorb burst pressure.
5. Keep performance regression checks in normal release process.

## Final takeaway

PostgreSQL tuning worked when I treated database performance as a system property: query design, index strategy, vacuum behavior, connection management, and operational observability all mattered together. Once those pieces aligned, latency became stable enough for confident releases.
