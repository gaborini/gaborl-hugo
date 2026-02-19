+++
title = "Special Project: AquaForge Aquaponics Digital Twin"
date = 2026-02-18T10:00:00-05:00
slug = "special-project-aquaforge-aquaponics-digital-twin"
tags = ["arduino", "raspberry pi", "rust", "digital-twin", "special-project"]
categories = ["Special Projects"]
metadescription = "A long-form project report on building a digital twin for aquaponics using Arduino, Raspberry Pi, and Rust."
metakeywords = "aquaponics digital twin, raspberry pi rust automation, arduino control"
+++

AquaForge started as a home-scale aquaponics controller and evolved into a real digital twin platform. The core idea was to move from reactive control to predictive operation: detect chemistry drift early, simulate intervention outcomes, and reduce both stress events and wasted inputs.

![Stock photo: aquaponics growing setup](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Portable_fish_farm_at_growing_power.jpg/1280px-Portable_fish_farm_at_growing_power.jpg)

*Stock photo source: Wikimedia Commons.*

![AquaForge architecture](/images/posts/special-projects/aquaforge-architecture.svg)

*Figure 1: System decomposition of AquaForge with hard real-time control at the edge and model-driven decision support.*

## Why a digital twin here

Aquaponics has tightly coupled loops:

- fish health,
- water chemistry,
- plant uptake,
- pump and aeration timing.

Small disturbances can cascade. A dashboard with static thresholds is not enough because interactions are time-dependent and nonlinear. The twin was designed to answer "what happens in the next 6-12 hours if we apply action X now?"

## Control split and safety design

I used a two-layer control pattern:

- Arduino Mega handled immediate actuator safety and interlocks.
- Raspberry Pi 5 handled higher-level optimization and forecast guidance.

If the Pi failed, the Arduino still kept the system safe with conservative fallback profiles. This separation was non-negotiable.

### Sensors and actuators

Key measured signals:

- pH,
- electrical conductivity,
- water temperature,
- dissolved oxygen proxy,
- pump current and flow estimate,
- canopy humidity and temperature.

Controlled outputs:

- circulation pump scheduling,
- aeration duty cycle,
- dosing valve windows,
- grow-light dimming,
- fan control.

## Data pipeline and Rust services

The Pi ran Rust services for ingest, validation, state estimation, and recommendation generation. I chose Rust here because low-latency streaming and strict error handling mattered more than rapid prototyping speed.

Core pipeline steps:

1. Ingest from Arduino and ESP32 nodes.
2. Validate and normalize units.
3. Update current state vector.
4. Simulate short-horizon scenarios.
5. Emit ranked recommendations with confidence.

This ranking step mattered for human adoption. Operators do not want ten options; they want two clear actions with expected impact.

## Twin model design

I avoided an overly complex model. The best-performing version used:

- a compact state-space representation,
- empirically tuned transfer coefficients,
- uncertainty bands derived from recent residuals.

The twin continuously compared prediction vs measured outcome and adjusted confidence, not the full structure, in real time. Full retraining happened offline.

## Operator UX and trust

Early versions failed one human test: they were technically right but operationally confusing. I changed the recommendation format to include:

- action,
- expected effect size,
- confidence,
- potential side effects,
- fallback plan.

That single change improved acceptance significantly.

Example recommendation object:

```json
{
  "action": "Increase aeration duty from 45% to 60% for 20 min",
  "expected_effect": "DO proxy +0.7 mg/L equivalent",
  "confidence": 0.81,
  "risk_note": "Slight pH rise likely",
  "fallback": "Revert duty if pH > 7.2"
}
```

## Validation and rollout

I ran the rollout in three phases:

- Observe-only (twin predicts, no control changes).
- Assisted mode (operator executes suggestions).
- Semi-automatic mode (low-risk actions auto-applied).

The long observe-only phase was critical for calibrating trust and model drift behavior.

## Pilot outcomes

![AquaForge outcomes](/images/posts/special-projects/aquaforge-results.svg)

*Figure 2: Pilot KPI changes after introducing model-guided control.*

Measured 8-week improvements:

- Water stability index: 0.58 -> 0.84.
- Feed waste reduction: 22 percent.
- Unplanned pump interruptions: 9 -> 2.
- Median drift detection latency: 52 minutes -> 14 minutes.

The project also reduced operator fatigue: less manual trial-and-error, fewer panic adjustments.

## Failures and fixes

Important failures:

- One dissolved oxygen sensor drifted silently.
- Initial dosing model overfit one warm-week pattern.
- Message burst spikes occasionally delayed recommendation refresh.

Fixes:

- added sensor redundancy checks,
- moved from single-week fit to rolling window constraints,
- introduced bounded queues with priority classes.

## Why this stands out

AquaForge is a "special project" because it combines:

- hard safety logic,
- interpretable short-horizon simulation,
- human-centered recommendation design,
- measurable biological and operational gains.

Most hobby systems optimize one layer. This one integrated control, modeling, and workflow into a coherent operating system.

## Next technical steps

Planned upgrades:

- explicit nutrient uptake submodel by growth stage,
- small vision module for leaf stress scoring,
- automated calibration planning based on residual drift,
- quarterly model benchmark datasets with reproducibility reports.

For anyone building a similar stack: prioritize deterministic data quality and operator trust long before you optimize model sophistication.
