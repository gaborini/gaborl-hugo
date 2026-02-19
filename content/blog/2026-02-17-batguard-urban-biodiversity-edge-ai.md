+++
title = "Special Project: BatGuard Urban Biodiversity Edge AI"
date = 2026-02-17T09:15:00-05:00
slug = "special-project-batguard-urban-biodiversity-edge-ai"
tags = ["raspberry pi", "rust", "edge-ai", "iot", "special-project"]
categories = ["Special Projects"]
metadescription = "Detailed deep dive into an edge AI acoustic monitoring network for bat activity in urban environments."
metakeywords = "edge ai acoustic monitoring, raspberry pi biodiversity, rust stream analytics"
+++

BatGuard is an urban biodiversity platform designed for one hard reality: ecological signals are noisy, and policy action requires credible evidence. The system captures ultrasonic activity, classifies probable species groups at the edge, and creates confidence-scored event timelines that city teams can use for interventions.

![Stock photo: bat close-up](https://upload.wikimedia.org/wikipedia/commons/7/77/Big-eared-townsend-fledermaus.jpg)

*Stock photo source: Wikimedia Commons.*

![BatGuard architecture](/images/posts/special-projects/batguard-architecture.svg)

*Figure 1: BatGuard data path from ultrasonic capture nodes to response workflows.*

## Project objective

The objective was not to build a classifier benchmark project. It was to support practical decisions:

- when to reduce decorative lighting,
- where to enforce temporary quiet windows,
- how to prioritize habitat interventions.

That meant we needed stable long-run operation and transparent uncertainty, not just high test-set accuracy.

## Field hardware strategy

I used two node types:

- Pi Zero 2 W ultrasonic capture nodes at critical points.
- low-cost ESP32 reference nodes for ambient context.

The reference nodes measured environmental noise and weather proxies. This extra context reduced classification confusion during rain, wind, and traffic bursts.

## Edge pipeline design

The edge hub (Pi 5) ran a Rust stream engine with fixed-latency processing stages:

1. Time-aligned ingest.
2. Spectrogram feature extraction.
3. Lightweight classifier inference.
4. Confidence calibration and deduplication.
5. Event packaging for conservation API.

The dedup stage mattered because raw detection streams can flood operators with duplicates. I used spatiotemporal clustering to collapse event storms into one actionable incident.

## Reliability engineering decisions

The deployment ran unattended for weeks, so I focused on maintainability:

- service supervision via `systemd`,
- bounded persistent queues,
- model bundle hot-swap with rollback,
- offline mode with delayed sync,
- heartbeat + clock drift monitoring.

A noisy city environment means frequent partial failures. The platform needed graceful degradation more than perfect uptime.

## Labeling and model loop

A purely static model underperformed by neighborhood. I implemented a feedback loop:

- uncertain events routed for manual review,
- reviewer labels fed into retraining batch,
- recalibration updates pushed monthly.

This loop improved local precision without requiring full retraining every week.

## Operational UX

Rangers and analysts received a map layer with:

- event confidence,
- trend deltas,
- likely disturbance drivers,
- recommended response templates.

The key insight: fewer high-quality alerts beat large noisy event volumes. We intentionally biased toward useful interventions, not maximal recall.

## Trial outcomes

![BatGuard results](/images/posts/special-projects/batguard-results.svg)

*Figure 2: Field metrics and intervention-oriented outcomes from 62 monitored nights.*

Pilot highlights:

- 1,842 valid activity windows detected.
- Manual review precision around 0.89.
- Median edge inference latency 62 ms.
- Energy budget 3.8 Wh per node per night.

Most important impact: city teams used the timelines to justify targeted quiet-hour interventions in high-activity windows.

## Engineering lessons

What went wrong first:

- false positives during heavy rain,
- inconsistent node clocks under aggressive power save,
- operator overload from early alert volume.

Fixes that worked:

- added ambient context features,
- introduced stricter sync checks,
- shifted to confidence-thresholded incident summaries.

## Why this qualifies as a special project

BatGuard merges edge AI, low-power design, conservation workflows, and policy-oriented outputs. It is unusual because the success metric is not only model quality. It is whether city teams can take better, faster, and defensible action.

## Next phase roadmap

Planned upgrades:

- federated adaptation by district,
- improved rain-robust feature set,
- multi-season habitat trend model,
- transparent uncertainty cards for public reporting.

If you build something similar, define decision outcomes first and model architecture second. That order prevents building technically impressive but operationally irrelevant systems.
