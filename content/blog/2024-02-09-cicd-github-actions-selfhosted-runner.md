+++
title = "CI/CD Retrospective: GitHub Actions with a Self-Hosted Runner"
date = 2024-02-09T09:00:00-05:00
slug = "cicd-retrospective-github-actions-with-a-self-hosted-runner"
tags = ["ci-cd", "github-actions", "devops", "automation", "deployment"]
categories = ["DevOps", "Automation"]
metadescription = "A detailed retrospective on building a safer CI/CD pipeline with GitHub Actions and a self-hosted runner for infrastructure and web deployments."
metakeywords = "github actions self hosted runner, ci cd deployment strategy, safe release pipeline"
+++

My earlier deployment flow relied too much on manual terminal sessions. It worked for small updates, but release quality depended on concentration and luck. In 2024, I moved to a structured GitHub Actions pipeline with a self-hosted runner for environment-specific deployment steps.

![Pexels stock photo: developer workstation](/images/posts/infrastructure/cicd-pipeline-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 577585](https://images.pexels.com/photos/577585/pexels-photo-577585.jpeg).* 

## Objectives

I optimized for:

- deterministic build and test behavior,
- controlled production promotions,
- fast rollback,
- complete release audit trail.

I intentionally did not optimize for "full auto deploy on every commit" in the first phase.

## Runner architecture

I used a split runner strategy:

- GitHub-hosted runners for lint, test, and generic build,
- one hardened self-hosted runner for deployment jobs that required private network access.

This reduced secret exposure and preserved repeatability.

## Pipeline stages

The final flow looked like this:

1. lint and static analysis,
2. unit/integration tests,
3. build artifact,
4. dependency and security scan,
5. staging deploy,
6. post-deploy smoke tests,
7. manual approval gate,
8. production deploy.

Each stage stayed rerunnable to avoid restarting the entire workflow for one late-stage failure.

## Release policy

I used trunk-based development with short-lived feature branches. Production rules were:

- `main` remained releasable,
- version tags triggered production pipeline,
- hotfix tags ran a shortened but still validated path.

This removed ambiguity about which commit could ship safely.

## Workflow gate example

```yaml
name: deploy
on:
  push:
    tags:
      - 'v*'

jobs:
  deploy_prod:
    needs: [build, test, security_scan, deploy_staging, smoke_staging]
    if: startsWith(github.ref, 'refs/tags/v')
    environment:
      name: production
    runs-on: [self-hosted, linux, deploy]
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/deploy-prod.sh
```

This gating prevented rushed shortcuts during high-pressure release windows.

## Secret handling and hardening

I improved secret hygiene by:

- rotating deployment credentials quarterly,
- limiting token scopes by environment,
- separating staging and production secret sets,
- auditing secret access via workflow logs.

On the self-hosted runner, I restricted outbound egress and disabled interactive shell access for normal jobs.

## Deployment mechanics

Production deploy used immutable artifacts and atomic release switch:

- CI built and signed artifact,
- deploy script verified checksum,
- release directory symlink switched atomically,
- service reload happened only after health checks passed.

Rollback was a controlled switch to previous artifact metadata.

## Incident that changed the pipeline

One release passed tests but failed at runtime due to wrong env-var mapping. After this incident, I added contract checks to validate required runtime configuration before deployment completion.

That one change prevented a repeated class of production failures.

## DORA-style tracking

I tracked:

- deployment frequency,
- lead time for changes,
- change failure rate,
- mean time to recovery.

After six weeks:

- deployment frequency increased,
- change failure rate decreased,
- rollback MTTR improved because rollback was mechanical.

## Tradeoffs and operating cost

Self-hosted runners require patching and lifecycle care. I accepted that because private-network deployment and tighter control were worth it for this stack. I documented runner rebuild as code to keep that maintenance predictable.

## Rules that stayed

1. No direct production deploy from laptops.
2. Only immutable artifacts are deployable.
3. Every production release runs smoke checks.
4. Manual approval exists only at defined boundaries.
5. Rollback path is tested regularly, not only documented.

## Final lesson

CI/CD delivered value not because it was "modern," but because it removed ambiguity from releases. Once every stage was explicit and logged, delivery became calmer and incident handling became faster.
