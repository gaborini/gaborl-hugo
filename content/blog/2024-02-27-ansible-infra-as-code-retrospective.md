+++
title = "Ansible Infra-as-Code Retrospective: How I Stopped Snowflake Servers"
date = 2024-02-27T09:00:00-05:00
slug = "ansible-infra-as-code-retrospective-how-i-stopped-snowflake-servers"
tags = ["ansible", "infrastructure-as-code", "linux", "automation", "devops"]
categories = ["DevOps", "Linux"]
metadescription = "A detailed retrospective on migrating small VPS and homelab hosts to Ansible-managed infrastructure with practical role and rollout patterns."
metakeywords = "ansible infra as code migration, ansible roles best practices, server configuration automation"
+++

By early 2024, I had too many hand-tuned servers. They looked similar from the outside, but each had slight differences in package versions, systemd overrides, firewall rules, and cron behavior. Incident response became slower because every fix started with one question: "what exactly is this host running?"

I solved that by moving to an Ansible-first operating model. This post is the retrospective after the first two months of migration.

![Pexels stock photo: coding on laptop](/images/posts/infrastructure/ansible-playbook-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 1181244](https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg).* 

## Why I chose Ansible for this phase

I needed a tool that:

- worked incrementally on existing machines,
- stayed readable for small-team collaboration,
- did not force a full platform rewrite,
- supported idempotent operations.

Ansible fit because I could start with one host and one role, then expand safely.

## Inventory design

My first attempt had over-engineered group nesting. Variable precedence became difficult to reason about during incidents.

I simplified to:

- one `group_vars/all.yml` for baseline defaults,
- explicit group files (`vps.yml`, `pi_nodes.yml`, `db_nodes.yml`),
- host-level overrides only for true exceptions.

This made configuration drift easier to explain and fix.

## Role structure that scaled

I built a role taxonomy with clear boundaries:

- `baseline_os`: packages, timezone, journald, shell profile,
- `security_hardening`: SSH, firewall, fail2ban, auditd,
- `web_edge`: nginx/apache config + service units,
- `observability_agent`: metrics and log shipping,
- `backup_client`: schedules, retention policy, restore hooks.

Each role had one primary responsibility and one smoke-check step.

## Idempotence and drift control

I enforced idempotence with mandatory dry-run before production apply.

```bash
ansible-playbook -i inventory/hosts.yml site.yml --check --diff
ansible-playbook -i inventory/hosts.yml site.yml --limit vps-prod
```

I also ran scheduled weekly dry-runs. If drift appeared, I fixed playbooks rather than patching hosts manually.

## Example task pattern that prevented regressions

```yaml
- name: Configure sshd with managed template
  ansible.builtin.template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    group: root
    mode: '0600'
  notify: Restart sshd

- name: Ensure sshd is enabled
  ansible.builtin.service:
    name: ssh
    state: started
    enabled: true
```

The critical pattern was pairing config changes with explicit handlers.

## Secret handling

I started with Ansible Vault, then split by use case:

- Vault for low-volume encrypted vars,
- CI-injected environment secrets for pipeline jobs,
- host-local secret files only where unavoidable.

The main lesson was to keep secret ownership and rotation paths documented in the repo.

## Rollout model

I never applied risky changes everywhere at once. The process was:

1. canary host apply,
2. health probe validation,
3. one host group rollout,
4. error/log review,
5. global rollout.

This serial pattern prevented at least two broad outages when upstream package behavior changed unexpectedly.

## Incident that validated the model

During one routine update, nginx behavior changed after a dependency bump on two test nodes. Because config was templated and versioned, I fixed it once and applied cleanly. Before this migration, that would have been a manual host-by-host hunt.

## Metrics I tracked

I tracked outcomes, not only "playbook success":

- mean host rebuild time,
- count of manual config edits per month,
- weekly drift findings,
- incident mitigation time.

After eight weeks:

- rebuild time dropped from roughly two hours to under 30 minutes,
- manual hotfix edits dropped significantly,
- drift findings became rare and quickly explainable.

## Mistakes I corrected

Early mistakes:

- templating too aggressively,
- putting too much logic in Jinja templates,
- weak variable naming conventions.

Fixes:

- move logic into tasks and defaults,
- keep templates focused on rendering,
- formalize variable naming and role docs.

## Guardrails I kept permanently

1. No direct manual edit on managed files.
2. Every role includes a smoke test step.
3. Risky role changes always go through canary rollout.
4. Incident fixes are encoded in playbooks immediately.
5. Weekly dry-run is mandatory.

## Final outcome

Ansible did not make operations perfect, but it made behavior reproducible and explainable. That was the real win. Once servers stopped being snowflakes, every other improvement got easier: hardening, backup consistency, and faster recovery during incidents.
