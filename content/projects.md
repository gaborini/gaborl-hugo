+++
title = "Projects"
+++

I build practical systems where hardware, software, and operations meet.
The common thread across my projects is simple: make devices and services that keep working outside ideal lab conditions.

![Electronics workbench project setup](/images/pages/projects-workbench.jpg)

*Photo: "Lamp controller & Arduino (3133281002)" by [Felipe Sanches](https://www.flickr.com/people/61604852@N00), licensed [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0/), via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Lamp_controller_%26_Arduino_(3133281002).jpg).*

## How I choose projects

I focus on projects that create measurable operational value, not only interesting demos.
Typical goals:

- reduce failure rates in unattended systems,
- shorten time-to-diagnose when something breaks,
- improve safety and recoverability,
- make deployment and maintenance repeatable.

If a project cannot explain who benefits and how success is measured, I usually do not continue it.

## Main project families

### 1. Embedded sensing and control

This includes Arduino and ESP-class builds for sensor acquisition, relay and actuator control, and local automation loops.
I prioritize deterministic behavior, explicit fault handling, and persistent diagnostic counters.

Typical patterns:

- validated sensor reads with quality flags,
- watchdog + staged recovery strategy,
- configuration schema versioning,
- power-aware scheduling for field nodes.

### 2. Raspberry Pi edge gateways

I use Raspberry Pi as local orchestration and reliability layers between constrained edge nodes and cloud/backoffice services.

Common responsibilities:

- protocol bridging (serial, Modbus, MQTT, LoRa),
- local buffering for offline resilience,
- service supervision with `systemd`,
- secure remote operations with VPN-based access.

### 3. Rust-based backend and tooling

Rust is my preferred language for ingest pipelines, validation services, event routing, and command-line tools in embedded workflows.

Why Rust in this stack:

- strong type-level guarantees around error handling,
- good async performance for stream processing,
- predictable behavior under load,
- maintainable long-term codebases for operational systems.

## Representative active project tracks

### Frost-risk edge network

Distributed sensor nodes and a Pi gateway predict local frost risk per vineyard row.
The focus is actionable warning lead time, not pretty charts.

### Aquaponics digital twin

A dual-loop control platform with hard real-time safety on Arduino and model-driven recommendations on Raspberry Pi + Rust.
The target is more stable chemistry and lower intervention cost.

### Retrofitted predictive maintenance

Legacy machine telemetry retrofit with feature extraction at the edge and risk scoring in a local Rust stream engine.
The main KPI is unplanned downtime reduction.

### Edge biodiversity monitoring

Acoustic sensing with confidence-scored event detection and operational workflows for response teams.
The key challenge is balancing recall and alert quality.

### Home microgrid orchestrator

Circuit-aware scheduling with tariff and forecast context, plus safe fallback profiles for outages.
The goal is lower cost, lower peak draw, and healthier battery cycles.

## Engineering standards I keep across projects

- Every system has a clearly defined failure model.
- Every deployed node exports minimal health telemetry.
- Every alert includes context and recommended action.
- Every major decision path is observable in logs or metrics.
- Every update path includes rollback strategy.

These standards prevent "works on my desk" architecture from reaching production unchanged.

## Documentation style for this blog

For each meaningful project, I try to publish:

- architecture overview,
- constraints and tradeoffs,
- implementation details,
- results and incident data,
- lessons learned and next iteration plan.

That format helps future me and other builders avoid repeating the same mistakes.

## Collaboration scope

I am especially interested in projects that combine:

- embedded reliability,
- edge computing,
- observability,
- and domain-specific operations (agri-tech, manufacturing, environmental monitoring).

If you like practical systems thinking and robust nerdy engineering, this page should give a clear picture of what I build.
