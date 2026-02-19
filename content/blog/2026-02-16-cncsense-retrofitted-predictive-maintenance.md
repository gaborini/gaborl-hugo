+++
title = "Special Project: CNCSense Retrofitted Predictive Maintenance"
date = 2024-07-30T09:00:00-05:00
slug = "special-project-cncsense-retrofitted-predictive-maintenance"
tags = ["arduino", "raspberry pi", "rust", "predictive-maintenance", "special-project"]
categories = ["Special Projects"]
metadescription = "A long project report about retrofitting legacy CNC machines with an edge predictive maintenance stack."
metakeywords = "cnc predictive maintenance, arduino vibration sensing, rust edge analytics"
+++

CNCSense was built to solve a common manufacturing pain: legacy machines fail without enough warning, and maintenance teams are forced into reactive firefighting. Replacing whole lines was not an option, so the project goal was retrofit-first predictive maintenance with minimal intrusion.

![Stock photo: CNC machine in workshop](https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/CNC_machine.jpg/1280px-CNC_machine.jpg)

*Stock photo source: Wikimedia Commons.*

![CNCSense architecture](/images/posts/special-projects/cncsense-architecture.svg)

*Figure 1: Retrofit topology across machine edge kit, PLC bridge, and Rust analytics hub.*

## Scope and constraints

The pilot had seven machines across mixed vintages. Constraints were strict:

- no firmware changes on core OEM controllers,
- minimal installation downtime,
- no dependency on permanent cloud connectivity,
- alerts must map to maintenance actions, not abstract anomalies.

## Retrofit sensor strategy

I selected a compact edge kit:

- tri-axis vibration sensor,
- spindle current sensing,
- machine cycle-state context from PLC bridge,
- optional acoustic channel for specific machines.

The main design rule was contextualization. Raw vibration amplitude without cycle phase or feed-rate context generated too many false signals.

## Edge processing and feature pipeline

Arduino Due handled first-pass signal conditioning and FFT windows. It transmitted compact features to Pi instead of full raw streams whenever possible.

Feature families used:

- spectral centroid drift,
- band energy ratios,
- transient spike density,
- cycle-normalized current deviation.

This reduced uplink load while preserving fault-discriminative information.

## Rust decision engine on Pi

The Pi 5 hosted a Rust stream engine with deterministic micro-batches. The decision model combined:

- short-window anomaly score,
- long-window trend score,
- operating context consistency,
- maintenance history priors.

The final output was a tool-wear risk with confidence and an expected lead time before fault threshold.

## Alert design for maintenance teams

Early alert versions failed because they were too technical. I changed each alert to include:

- probable component area,
- urgency window,
- confidence,
- supporting feature explanation,
- suggested next inspection step.

This directly increased adoption by technicians.

Example alert payload:

```json
{
  "machine_id": "cnc-04",
  "risk": "HIGH",
  "confidence": 0.86,
  "lead_time_min": 41,
  "suspected_component": "spindle bearing set",
  "evidence": ["high-frequency band drift", "current ripple increase"],
  "recommended_action": "Inspect bearing preload at next micro-stop"
}
```

## Rollout approach

I used a staged rollout:

1. Passive observation with no alerts to teams.
2. Internal alert validation with maintenance lead.
3. Controlled live alerts on two lines.
4. Full pilot with weekly calibration review.

This prevented trust collapse from early noisy alarms.

## Pilot outcomes

![CNCSense results](/images/posts/special-projects/cncsense-results.svg)

*Figure 2: Operational impact from the 12-week retrofit pilot.*

Measured effects:

- unexpected spindle stop events: 18 -> 7,
- estimated downtime reduction: 26 percent,
- scrap reduction on monitored lines: 11 percent,
- average actionable lead time: 43 minutes.

False alerts remained under 10 percent after contextual rule tuning.

## Failure cases and iteration

Main failure cases:

- alarm storms during atypical heavy-cut jobs,
- sensor mount looseness on one machine,
- edge queue backlog when diagnostic mode was enabled too often.

Resolved with:

- job-class-aware scoring weights,
- mount design revision,
- strict bounded telemetry mode policies.

## Why this project is special

CNCSense is special because it delivers measurable reliability gains without replacing legacy equipment. The combination of retrofit hardware, context-rich analytics, and technician-centered alert design made it practical, not just experimental.

## Next milestone

Planned next phase:

- cross-machine transfer learning,
- automatic work-order drafting from alerts,
- closed-loop verification between maintenance action and risk decay,
- per-shift confidence drift monitoring.

If you retrofit industrial assets, build around operator workflow and action latency. Predictive models only matter when they create timely, trusted interventions.
