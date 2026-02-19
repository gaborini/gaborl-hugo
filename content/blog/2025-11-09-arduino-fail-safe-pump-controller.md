+++
title = "Designing a Fail-Safe Pump Controller with Arduino"
date = 2025-11-09T09:00:00-05:00
slug = "designing-a-fail-safe-pump-controller-with-arduino"
tags = ["arduino", "automation", "safety", "control-systems", "relays"]
categories = ["Arduino"]
metadescription = "Detailed design guide for a fail-safe Arduino pump controller with clear safety states and recovery logic."
metakeywords = "arduino pump controller, fail safe relay control, automation safety"
+++

A pump controller is not a toy project once water, pressure, and unattended operation are involved. The goal is not just controlling a relay. The goal is to guarantee safe behavior when sensors fail, wiring degrades, or power quality drops.

## 1. Safety assumptions and hazard list

Start with hazards, not code:

- Dry run can damage pump hardware
- Stuck relay can overfill tanks
- Sensor drift can cause silent bad decisions
- Reboot during active cycle can leave outputs unsafe

For each hazard, define a mitigation in firmware and hardware. If one mitigation fails, the second one should still reduce risk.

## 2. Hardware safety architecture

I recommend this arrangement:

- Pump relay defaults to OFF on MCU reset
- Float switch wired as independent hardware interlock
- Current sensor to detect pump running unexpectedly
- Separate fuse for pump power branch
- Physical emergency stop switch in series with relay output

The interlock path should not rely only on software logic.

## 3. Explicit finite state machine

Use an explicit state machine to prevent contradictory behavior:

- `IDLE`
- `PRIMING`
- `PUMPING`
- `COOLDOWN`
- `FAULT_LATCHED`

Each transition has entry and exit conditions. Example:

- `PUMPING -> FAULT_LATCHED` when dry-run signal is active for 3 consecutive samples.
- `FAULT_LATCHED -> IDLE` only after operator acknowledgement and sensor health check.

This structure is easier to audit than nested `if` blocks.

## 4. Timing and anti-chatter policy

Never switch pump state directly on single-threshold crossings. Add hysteresis and minimum run windows:

- Minimum ON duration: protects relay contacts and motor startup
- Minimum OFF duration: prevents rapid restart cycles
- Sensor debounce windows: smooth mechanical switch noise

These values should be configurable through persistent settings with bounds validation.

## 5. Fault detection signals

A robust controller combines multiple signals:

- Level sensor indicates demand
- Current sensor confirms motor actually runs
- Runtime watchdog checks max cycle duration
- Optional pressure sensor verifies expected hydraulic response

If command says ON but current remains zero, classify as actuation fault. If current is high but level does not change, classify as possible blockage.

## 6. Recovery strategy

Use staged recovery, not immediate repeated retries:

1. First fault: stop pump, wait cooldown, retry once
2. Second fault in same window: lock into `FAULT_LATCHED`
3. Require manual reset to continue

Manual reset is a feature, not an inconvenience, for systems with real physical risk.

## 7. Logging that helps postmortems

Log these event types with timestamps:

- state transitions
- command outputs
- fault reasons
- reset causes
- operator acknowledgements

Postmortem quality depends on event logs. Without them, teams tend to blame hardware randomly.

## 8. Commissioning test protocol

Before production:

- Simulate dry-run and overfill conditions
- Force sensor disconnections during operation
- Power cycle during each state
- Validate safe startup after unexpected reset

If the controller passes these tests cleanly, confidence is earned, not assumed.

## Final note

Fail-safe design is about predictable behavior under bad conditions. Arduino can be fully suitable for this class of project when state modeling, hardware interlocks, and fault latching are built in from the start.
