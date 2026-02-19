+++
title = "KiCad PCB Review Checklist Before Sending to Fabrication"
date = 2024-06-09T09:00:00-05:00
slug = "kicad-pcb-review-checklist-before-sending-to-fabrication"
tags = ["kicad", "pcb", "electronics", "hardware", "design-review"]
categories = ["Electronics"]
metadescription = "A detailed PCB review checklist in KiCad to reduce re-spins and manufacturing surprises."
metakeywords = "kicad pcb checklist, pcb design review, hardware bring-up"
+++

PCB re-spins are expensive in time and momentum. A disciplined pre-fabrication review catches most avoidable failures. This checklist focuses on practical issues seen in mixed embedded boards.

## 1. Schematic sanity checks

Before layout details, confirm schematic intent:

- power domains clearly separated
- decoupling per IC present and sized
- net names meaningful and consistent
- unused inputs handled correctly

Ambiguous schematic intent usually becomes ambiguous layout decisions.

## 2. Library and footprint verification

For each critical component:

- verify footprint against manufacturer drawing
- confirm pin 1 orientation marker
- check pad dimensions and courtyard
- validate connector mechanical alignment

Never assume third-party library footprints are correct.

## 3. Power routing review

Inspect power nets for:

- adequate trace width for expected current
- clean return paths
- proper grounding strategy
- separation between noisy and sensitive rails

Power integrity mistakes are a major source of first-article failures.

## 4. Signal integrity basics

For faster or sensitive signals:

- keep clocks short and isolated
- avoid unnecessary stubs
- maintain differential pair symmetry where required
- control trace proximity to switching nodes

You do not need RF-level complexity for most boards, but basic discipline matters.

## 5. DRC/ERC plus human review

Run KiCad ERC/DRC, then perform manual review anyway. Automated checks miss context-specific mistakes, especially connector pin swaps and net intent errors.

Use a second pair of eyes when possible.

## 6. Manufacturing constraints

Match board house capabilities:

- min trace/space
- drill sizes
- solder mask clearance
- board thickness and copper weight

Designing outside fab limits causes delays or silent auto-modification.

## 7. Bring-up aids

Add features that simplify debugging:

- test points for key rails and buses
- boot mode straps accessible
- status LED
- optional current measurement jumper

These small additions save significant bring-up time.

## 8. Output package verification

Before release:

- regenerate Gerbers and drill files cleanly
- inspect with independent viewer
- verify BOM and pick-and-place alignment
- include assembly notes and polarity markers

Treat manufacturing output as a release artifact with versioning.

## Final note

A strong KiCad review process reduces hardware risk dramatically. Most expensive errors are preventable with a consistent checklist and one disciplined final pass.
