+++
title = "Raspberry Pi Backup and Disaster Recovery That Actually Works"
date = 2024-10-18T09:00:00-05:00
slug = "raspberry-pi-backup-and-disaster-recovery-that-actually-works"
tags = ["raspberry pi", "backup", "disaster-recovery", "linux", "operations"]
categories = ["Raspberry Pi"]
metadescription = "A detailed disaster recovery plan for Raspberry Pi systems including backup scope, restore drills, and validation."
metakeywords = "raspberry pi backup strategy, pi disaster recovery, restic backups"
+++

Many Pi setups claim to have backups but fail the first real restore. A backup is only valid if recovery has been tested against realistic failure scenarios. This post describes a practical recovery design for personal labs and small production deployments.

## 1. Define recovery goals

Write these values explicitly:

- RPO: maximum acceptable data loss
- RTO: maximum acceptable recovery time
- Critical services list in recovery order

Example: telemetry ingestion might need fast RTO, while historical archives can wait.

## 2. Backup scope classification

Split data into classes:

- system configuration (`/etc`, service files)
- application state (databases, queues)
- user data and media
- secrets and keys

Treat secrets separately with tighter access controls and rotation policy.

## 3. Tooling and storage layout

A robust pattern:

- `restic` or equivalent for encrypted incremental backups
- local fast backup target (USB SSD or NAS)
- remote off-site copy for disaster scenarios

Follow the 3-2-1 principle:

- 3 copies
- 2 different media types
- 1 copy off-site

## 4. Scheduling and consistency

Use `systemd` timers or trusted schedulers, not manual runs. For stateful services:

- quiesce writes or snapshot consistent state
- dump databases with versioned naming
- run backup immediately after dump

Inconsistent snapshots are common and often unnoticed until restore time.

## 5. Restore drill workflow

At least monthly, perform a full drill on spare hardware or VM:

1. Provision clean OS
2. Restore configs and secrets
3. Restore application data
4. Start services in dependency order
5. Run smoke tests and compare metrics

Document exact commands and timings. If recovery steps exist only in memory, they will fail under pressure.

## 6. Backup validation automation

Add automated checks:

- backup completion status
- repository integrity check
- random file restore test
- alert if no successful backup in expected window

Silent backup failures are common. Monitoring backup freshness is mandatory.

## 7. Incident response checklist

When failure happens:

- classify incident type (disk loss, corruption, compromise)
- choose appropriate restore point
- rotate compromised credentials after restore
- verify service correctness, not only process startup

A service can be up and still wrong due to stale or partial data.

## 8. Post-incident learning

After recovery:

- update runbook with missing steps
- adjust retention and frequency if RPO missed
- remove manual steps by automation where possible

Each incident should leave the platform stronger.

## Final note

Disaster recovery is a practice, not a file dump. If you can restore quickly from a written runbook on a bad day, your backup strategy is working.
