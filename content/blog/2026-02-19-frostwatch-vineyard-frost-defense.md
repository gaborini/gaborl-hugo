+++
title = "Special Project: Frostwatch Vineyard Frost Defense Network"
date = 2024-06-23T09:00:00-05:00
slug = "special-project-frostwatch-vineyard-frost-defense-network"
tags = ["arduino", "raspberry pi", "rust", "lora", "special-project"]
categories = ["Special Projects"]
metadescription = "A full project deep dive into a solar-powered LoRa frost prediction and mitigation system for vineyards."
metakeywords = "lora frost detection, vineyard iot, raspberry pi rust edge"
+++

Frostwatch is one of the most practical systems I have built: a distributed frost-risk platform for vineyards where timing matters more than dashboards. If you detect frost risk 20 minutes too late, the damage is already done. The objective was simple to state and hard to deliver: create an edge-first system that predicts frost risk per row, survives bad weather and connectivity loss, and triggers mitigation actions with high confidence.

![Stock photo: vineyard landscape](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Vineyards_in_Burgundy_France.jpg/1280px-Vineyards_in_Burgundy_France.jpg)

*Stock photo source: Wikimedia Commons.*

![Frostwatch architecture](/images/posts/special-projects/frostwatch-architecture.svg)

*Figure 1: End-to-end Frostwatch architecture from field nodes to operations dashboard.*

## Problem definition and constraints

The pilot site had microclimate differences between rows that were not visible in one central weather station. We had several constraints:

- Irregular cellular coverage in low terrain pockets.
- Strict power budget for remote nodes.
- Need for resilient operation during storms.
- Operators who wanted clear action recommendations, not raw numbers.

The project target was to reduce frost damage incidents by at least 20 percent compared to the previous season while keeping false alerts low enough for operators to trust the system.

## Hardware architecture

I used a split architecture:

- Edge sensor nodes with ESP32 + LoRa and Arduino MKR WAN variants.
- One Raspberry Pi 5 gateway with a concentrator HAT.
- Independent power stack (small panel + LiFePO4 + charge controller).

Each field node measured air temperature, humidity, and soil temperature. Selected rows also had wind sensors for boundary-layer context. I intentionally avoided over-instrumenting every row and focused on a mixed dense-sparse placement strategy: dense around known frost pockets, sparse elsewhere.

### Power strategy

Power was the first reliability bottleneck. The final node firmware had three operation modes:

- Normal mode: report every 90 seconds.
- Elevated risk mode: report every 30 seconds.
- Critical mode: report every 20 seconds and prioritize frost metrics.

A stateful energy governor adjusted uplink behavior by battery state and panel history, but never suppressed critical alerts.

## Firmware and edge reliability model

Each node used a deterministic task loop with explicit deadlines. Every sensor read path had timeout + retry + quality flag output. Invalid samples were never silently dropped; they were marked with reason codes.

Example risk packet payload:

```json
{
  "node_id": "row-12-north",
  "ts": "2026-02-18T03:22:10Z",
  "air_temp_c": -1.4,
  "soil_temp_c": 1.1,
  "rh_pct": 93.2,
  "wind_ms": 0.8,
  "battery_v": 3.79,
  "sample_quality": "OK",
  "risk_score": 0.82
}
```

On communication failure, nodes kept a bounded local buffer with compact binary snapshots, then replayed in order. This prevented event timeline gaps during transient outages.

## Gateway and Rust services

The Raspberry Pi ran four services:

- LoRa packet forwarder.
- Rust ingest validator.
- Risk aggregation engine.
- Alert dispatcher with SMS fallback.

Validation rules rejected impossible transitions (for example, humidity jumps that violated sensor slope boundaries). The risk engine combined point risk and spatial continuity across nearby rows. This reduced overreaction to single-sensor noise.

I implemented an event confidence model that fused:

- sensor quality score,
- temporal persistence,
- neighborhood agreement,
- weather trend direction.

Only high-confidence frost events triggered actionable alerts.

## Risk model and agronomic mapping

The model blended dew point spread, canopy cooling trend, and local wind suppression indicators. The important practical detail was calibrating model outputs to operator language:

- Risk 0.00-0.35: monitor only.
- Risk 0.36-0.65: prepare mitigation assets.
- Risk 0.66-0.80: pre-activation recommended.
- Risk 0.81-1.00: activate mitigation now.

Instead of exposing model internals, the dashboard gave an explanation string for each high-risk row (for example: "persistent near-freezing canopy + low wind + rising humidity").

## Deployment and test protocol

Before the seasonal rollout, I ran a staged test plan:

1. Bench validation with simulated sensor curves.
2. 72-hour outdoor soak test in one row.
3. Controlled disconnect tests for gateway and selected nodes.
4. Operator shadow phase where alerts were logged but not acted on.

The shadow phase was critical because it let us tune confidence thresholds before real interventions.

## Observed results

![Frostwatch results](/images/posts/special-projects/frostwatch-results.svg)

*Figure 2: Pilot outcome trends and risk-confidence behavior during the first 21 days.*

Pilot outcomes vs previous season baseline on monitored rows:

- Frost damage incidents reduced by 31 percent.
- Median warning lead time improved to 46 minutes.
- False high-priority alerts stayed below 11 percent.
- Node uptime across weather events remained above 98 percent.

The biggest operational win was not the model itself, but trust. Operators started acting on alerts because the system showed confidence and context, not just thresholds.

## Hard lessons

Three issues cost time:

- Cable moisture ingress on two early nodes.
- Aggressive retry loops that briefly starved sensor tasks.
- Overly sensitive first-pass risk weighting under calm wind nights.

All three were fixed with hardware sealing improvements, backoff-aware scheduler tuning, and risk weight recalibration by historical replay.

## What made this project "special"

Many IoT weather projects stop at charting. Frostwatch closed the loop from sensing to action:

- edge-first reliability,
- interpretable risk,
- operationally meaningful alerts,
- measurable crop impact.

That combination is what turned it from a neat prototype into a system growers actually kept using.

## Next phase

The next iteration will focus on:

- short-horizon per-row thermal simulation,
- collaborative mitigation scheduling across adjacent blocks,
- low-bandwidth model updates to edge gateways,
- seasonal transfer-learning for site-specific calibration.

If you plan a similar system, start with reliability and operator workflow before model complexity. In the field, resilient behavior beats elegant theory every time.
