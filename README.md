# agentops-powderline

Milestone-driven agent orchestration for [OpenClaw](https://github.com/openclaw/openclaw). Picks GitHub issues, plans an approach via **RouteFinder**, implements via **LineRipper**, and opens a PR.

## How It Works

```
User: "Run Powderline on track-forge/crucible issue #44"

Coordinator → gathers issue/milestone context
           → prepares worktree + mission packet
           → spawns RouteFinder (plan pass)
           → spawns LineRipper (code pass)
           → reports PR URL
```

The coordinator agent owns orchestration. RouteFinder owns planning. LineRipper owns implementation. Durable artifacts (`.powderline/mission.md`, `.powderline/plan.md`) pass between them — no chat-only handoff.

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

The coordinator will:
1. Clone/fetch the repo to `~/repos/{org}/{repo}/`
2. Create a worktree at `.worktrees/issue-{N}/`
3. Write a mission packet to `.powderline/mission.md`
4. Spawn RouteFinder to write `.powderline/plan.md`
5. Spawn LineRipper to implement and open a PR

## Labels

- `agentops:plan-ready` — plan complete
- `agentops:pr-ready` — PR opened
- `agentops:blocked` — workflow stopped
- `agentops:needs-human-review` — human judgment required

## MVP Scope

One repo + one issue + optional milestone → plan → code → PR.

Not yet implemented: parallel milestone execution, auto-merge, review agents, dashboards.
