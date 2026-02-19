+++
title = "Learning"
+++

This page tracks what I am actively learning, how I learn it, and where I want to push my technical depth next.
I treat learning like engineering: explicit goals, measurable progress, and frequent iteration.

![Raspberry Pi board for edge learning projects](/images/pages/learning-raspberry-pi.jpg)

*Photo: "Raspberry Pi 2 Model B v1.1 front angle" by [Multicherry](https://commons.wikimedia.org/wiki/User:Multicherry), licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Raspberry_Pi_2_Model_B_v1.1_front_angle.jpg).*

## Current deep-focus areas

### 1. Reliable edge telemetry under real-world constraints

I am deepening my understanding of how to keep telemetry pipelines trustworthy when links are unstable, power is limited, and sensors drift.

What I am practicing:

- bounded buffering and replay design,
- schema evolution without breaking consumers,
- device-side data quality metadata,
- validation gates across ingest boundaries.

### 2. Linux operations for small edge fleets

I am improving my operational discipline for Raspberry Pi and similar devices deployed in unattended environments.

Key learning topics:

- `systemd` service and timer design patterns,
- update and rollback procedures,
- secure remote access and network segmentation,
- backup and disaster recovery drills.

### 3. Rust for long-lived systems

I continue to invest in Rust for systems that must stay maintainable for years.

Current focus:

- error taxonomy and context-rich propagation,
- async architecture with backpressure control,
- trait-driven boundaries for testability,
- cross-compilation and release pipeline hardening.

### 4. Control systems and signal quality

I am actively studying practical calibration, filtering, and control loop stability in embedded systems.

Topics in progress:

- sensor calibration workflows and drift monitoring,
- filter latency tradeoffs in control paths,
- PID behavior under noisy measurements,
- fault-tolerant actuator logic.

## 2026 learning roadmap

### Q1: Reliability foundations

- strengthen edge fault models,
- tighten observability baselines,
- standardize runbooks for recovery scenarios.

### Q2: Model-informed automation

- expand digital-twin style control support,
- improve uncertainty communication in recommendations,
- benchmark policy behavior against real event data.

### Q3: Fleet-level scale concerns

- safer OTA rollout patterns,
- multi-device configuration governance,
- better cost/latency profiling across architectures.

### Q4: Tooling and knowledge transfer

- package recurring workflows into reusable templates,
- publish longer technical postmortems,
- improve onboarding docs for collaborators.

## My learning workflow

I rely on a repeatable loop:

1. Pick one constrained real problem.
2. Build a minimal but testable implementation.
3. Stress it with failure scenarios.
4. Instrument and observe behavior.
5. Refactor with clearer interfaces.
6. Document what changed and why.

This keeps learning grounded in systems that actually run, fail, and recover.

## What "progress" means here

I do not consider a topic learned when I can explain it in theory.
I consider it learned when I can:

- design a reliable baseline,
- detect and classify failures quickly,
- recover safely without guesswork,
- and explain tradeoffs clearly to others.

That standard makes learning slower, but much more durable.

## Near-term experiments I want to run

- adaptive sampling strategies for battery-backed nodes,
- confidence-aware alerting for mixed-sensor environments,
- Rust ingest pipelines with formalized load-shedding policies,
- edge-node security hardening templates for rapid deployments.

This page will evolve as those experiments move from notes to repeatable patterns.
