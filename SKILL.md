---
name: powderline
description: "Orchestrate milestone-driven GitHub issue workflows with plan/code subagent passes."
---

# Powderline

Milestone-driven agent orchestration. Picks up GitHub issues, plans an approach, then codes and PRs the solution.

## Workflow

1. Read milestone and select unassigned/open issue.
2. Branch from target base (e.g. `milestone/<N>/issue-<ID>` off `feature/<name>`).
3. **Plan pass** — explore repos, read code, write implementation plan.
4. **Code pass** — implement plan, commit, open PR into target branch.
5. Report status back to coordinator.

## Configuration

- `POWDERLINE_REPO` — target GitHub repo (e.g. `track-forge/some-project`)
- `POWDERLINE_MILESTONE` — milestone number or name
- `POWDERLINE_BASE_BRANCH` — branch PRs target (e.g. `feature/foo`)
- `POWDERLINE_BRANCH_PATTERN` — branch naming template (default: `milestone/{milestone}/issue-{issue}`)
