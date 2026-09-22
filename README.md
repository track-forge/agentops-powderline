# agentops-powderline

Milestone-driven agent orchestration for [OpenClaw](https://github.com/openclaw/openclaw). Picks GitHub issues, maps relevant repository terrain via **Scout**, plans an approach via **RouteFinder**, implements via **LineRipper**, and opens a PR. **Soloist** handles explicitly assigned bounded tasks end to end.

## How It Works

```
User: "Run Powderline on track-forge/crucible issue #44"

Coordinator → gathers issue/milestone context
           → prepares worktree + mission packet
           → spawns Scout (bounded repository recon)
           → spawns RouteFinder (plan pass)
           → spawns LineRipper (code pass)
           → repairs failing CI with bounded LineRipper retries
           → spawns RouteFinder (plan-aware review pass)
           → reports PR URL
```

The coordinator agent owns orchestration. Scout owns bounded repository
reconnaissance. RouteFinder owns planning and review. LineRipper owns
implementation and bounded CI repair. Durable artifacts
(`.powderline/mission.md`, `.powderline/recon.md`, `.powderline/plan.md`,
`.powderline/review.md`) pass between them — no chat-only handoff.

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
model-routing.yaml               — runtime model routing for subagent spawns
agents/scout/                     — bounded reconnaissance agent workspace templates
agents/routefinder/               — planning subagent workspace templates
agents/lineripper/                — coding subagent workspace templates
agents/soloist/                   — general-purpose execution workspace templates
assets/                           — mission, plan, and PR body templates
references/                       — labels, milestone rules, workspace layout docs
scripts/install.sh                — install into an OpenClaw instance
scripts/validate-layout.sh        — verify all required files exist
```

## Model Routing

`model-routing.yaml` controls the runtime model passed to each Powderline
`sessions_spawn` call. Routing is enabled in the shipped profile:

```yaml
modelRouting:
  enabled: true
  scoutEnabled: true
  scout: openai-codex/gpt-5.6-luna
  standard: openai-codex/gpt-5.6-terra
  frontier: openai-codex/gpt-5.6-sol
  fallback: existing
  scoutMaxBytes: 8192
```

The workflow uses `scout` for a bounded reconnaissance pass, `standard` for
Soloist, planning, implementation, the first CI repair, and review, and
`frontier` for a final CI repair after the first repair fails. Scout writes a
cacheable `.powderline/recon.md` capped by `scoutMaxBytes`; set
`scoutEnabled: false` to skip that phase while retaining model routing.
Recon is reused only when its base SHA and issue-body SHA-256 still match. A
blocked, malformed, stale, or oversized recon is recorded and ignored;
RouteFinder continues with ordinary discovery rather than blocking the run.

Set `enabled: false` to omit runtime model overrides. With `fallback: existing`,
a spawn rejected because its requested model is unavailable is retried once
without `model`, allowing the configured `agents.list[]` model to take over.
Edit the installed copy at
`~/.openclaw/workspace/skills/agentops-powderline/model-routing.yaml` to match
the model identifiers available to that OpenClaw installation.

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
4. Spawn Scout to write a bounded `.powderline/recon.md`
5. Spawn RouteFinder to verify the recon and write `.powderline/plan.md`
6. Spawn LineRipper to implement and open a PR
7. Repair failed CI with at most two targeted LineRipper passes
8. Spawn RouteFinder to compare the PR diff against the original plan and write `.powderline/review.md`

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
