# agentops-powderline

Milestone-driven agent orchestration for [OpenClaw](https://github.com/openclaw/openclaw). Picks GitHub issues, plans an approach via **RouteFinder**, implements via **LineRipper**, and opens a PR. **Soloist** handles explicitly assigned bounded tasks end to end.

## How It Works

```
User: "Run Powderline on track-forge/crucible issue #44"

Coordinator → gathers issue/milestone context
           → prepares worktree + mission packet
           → spawns RouteFinder (plan pass)
           → spawns LineRipper (code pass)
           → repairs failing CI with bounded LineRipper retries
           → spawns RouteFinder (plan-aware review pass)
           → reports PR URL
```

The coordinator agent owns orchestration. RouteFinder owns planning and review. LineRipper owns implementation and bounded CI repair. Durable artifacts (`.powderline/mission.md`, `.powderline/plan.md`, `.powderline/review.md`) pass between them — no chat-only handoff.

For smaller or operational tasks, the coordinator may explicitly invoke Soloist.
Soloist inspects, plans internally, executes, verifies, and returns the requested
PR, issue comment, artifact, report, or task-specific result. Automatic routing to
Soloist is intentionally not defined; the standard issue flow remains RouteFinder
→ LineRipper unless Soloist is explicitly requested.

## Install

```bash
git clone git@github.com:track-forge/agentops-powderline.git
cd agentops-powderline
./scripts/install.sh ~/.openclaw
```

The install script copies skill files, agent workspace templates, and prints the `agents.list[]` JSON entries you need to add to `openclaw.json`.

## Structure

```
SKILL.md                          — coordinator workflow (OpenClaw skill)
agents/routefinder/               — planning subagent workspace templates
agents/lineripper/                — coding subagent workspace templates
agents/soloist/                   — general-purpose execution workspace templates
assets/                           — mission, plan, and PR body templates
references/                       — labels, milestone rules, workspace layout docs
scripts/install.sh                — install into an OpenClaw instance
scripts/validate-layout.sh        — verify all required files exist
```

## Usage

After installation, tell your coordinator agent:

```
Run Powderline on {org}/{repo} issue #{N}
```

Or with a milestone:

```
Run Powderline on {org}/{repo} issue #{N} (milestone: "Content Makeover")
```

For one bounded plan-and-execute pass:

```
Run this task with Powderline Soloist: {objective, scope, expected outcome, and verification}
```

The coordinator will:
1. Clone/fetch the repo to `~/repos/{org}/{repo}/`
2. Create a worktree at `.worktrees/issue-{N}/`
3. Write a mission packet to `.powderline/mission.md`
4. Spawn RouteFinder to write `.powderline/plan.md`
5. Spawn LineRipper to implement and open a PR
6. Repair failed CI with at most two targeted LineRipper passes
7. Spawn RouteFinder to compare the PR diff against the original plan and write `.powderline/review.md`

## Labels

- `agentops:plan-ready` — plan complete
- `agentops:pr-ready` — PR opened
- `agentops:blocked` — workflow stopped
- `agentops:needs-human-review` — human judgment required

## MVP Scope

One repo + one issue + optional milestone → plan → code → PR.

Not yet implemented: parallel milestone execution, auto-merge, dashboards.

Soloist auto-selection is also out of scope. Invoke it explicitly when its
single-agent execution model is the right fit.
