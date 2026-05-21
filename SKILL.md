---
name: agentops-powderline
description: "Orchestrate GitHub issue work through RouteFinder (planning) and LineRipper (coding) subagents."
---

# Powderline

Milestone-driven agent orchestration. You are the coordinator. You gather context, prepare the workspace, spawn subagents, and report results. You do not plan the implementation or write the code yourself.

## Trigger

Use this skill when asked to:
- Run Powderline on a repo/issue
- Plan and implement a GitHub issue via subagents
- Work a milestone issue through the plan/code pipeline

## Coordinator Workflow

### Phase 1: Gather Context

1. Resolve the target repo and issue number from the user's request.
2. Read the issue title, body, labels, and comments via `gh` or GitHub API.
3. If the issue belongs to a milestone, read the milestone description.
4. Extract `## Powderline Rules` from the milestone description if present (see `references/milestone-rules.md`).

### Phase 2: Resolve Branches

Determine the base branch in this order:
1. Explicit user instruction
2. Milestone Powderline Rules `Base branch` field
3. Repo default branch
4. `main`

Determine the PR target in this order:
1. Milestone Powderline Rules `PR target` field
2. Same as base branch

Issue branch pattern (default: `issue/{issue_number}-{slug}`):
1. Milestone Powderline Rules `Issue branch pattern` field
2. Default pattern

### Phase 3: Prepare Workspace

1. Ensure the local repo clone exists at `~/repos/{org}/{repo}`. Clone if missing.
2. Fetch latest refs: `git fetch --all`.
3. Create or reuse the issue worktree at `~/repos/{org}/{repo}/.worktrees/issue-{issue_number}`.

Worktree reuse rules:
- If the worktree exists, check `git status --short`.
- Ignore `.powderline/` files.
- If unrelated dirty files exist, stop and report `agentops:blocked`.
- If it belongs to the same issue, reuse it.
- Never delete or reset an existing worktree without explicit user instruction.

4. Create `.powderline/` in the worktree root.
5. Add `.powderline/` to `.git/info/exclude` if not already present.

### Phase 4: Write Mission Packet

Write `.powderline/mission.md` using the mission template structure (see `assets/mission-template.md`). Fill in all sections with the gathered context.

Write or update `.powderline/run.json`:

```json
{
  "repo": "{org}/{repo}",
  "issue_number": {N},
  "milestone": "{milestone_name}",
  "base_branch": "{base_branch}",
  "pr_target": "{pr_target}",
  "issue_branch_pattern": "{pattern}",
  "local_clone": "~/repos/{org}/{repo}",
  "worktree": "~/repos/{org}/{repo}/.worktrees/issue-{N}",
  "mission_path": "{worktree}/.powderline/mission.md",
  "plan_path": "{worktree}/.powderline/plan.md",
  "status": "initialized"
}
```

### Phase 5: Spawn RouteFinder

Update `run.json` status to `planning`.

Spawn the planning subagent:

```
sessions_spawn:
  agentId: "routefinder"
  context: "isolated"
  task: |
    You are RouteFinder. Read your SOUL.md and AGENTS.md for operating instructions.

    Your mission file is at: {worktree}/.powderline/mission.md
    Your worktree is at: {worktree}

    Read the mission, inspect the codebase, and write your plan to:
    {worktree}/.powderline/plan.md

    Return POWDERLINE_PLAN_READY or POWDERLINE_PLAN_BLOCKED per your output contract.
```

Wait for RouteFinder's announcement.

### Phase 6: Handle Plan Result

Parse the announced result for `POWDERLINE_PLAN_READY` or `POWDERLINE_PLAN_BLOCKED`.

**If PLAN_READY:**
- Update `run.json` status to `plan-ready`.
- Apply or recommend `agentops:plan-ready` label on the issue.
- Proceed to Phase 7.

**If PLAN_BLOCKED:**
- Update `run.json` status to `plan-blocked`.
- Apply or recommend `agentops:blocked` label.
- If `HumanReview: true`, also apply `agentops:needs-human-review`.
- Report the block reason to the user. Stop here.

### Phase 7: Spawn LineRipper

Update `run.json` status to `coding`.

Spawn the coding subagent:

```
sessions_spawn:
  agentId: "lineripper"
  context: "isolated"
  task: |
    You are LineRipper. Read your SOUL.md and AGENTS.md for operating instructions.

    Your mission file is at: {worktree}/.powderline/mission.md
    Your plan file is at: {worktree}/.powderline/plan.md
    Your worktree is at: {worktree}

    Read the mission and plan, implement the change, verify it, and open a PR.

    Return POWDERLINE_PR_READY or POWDERLINE_CODE_BLOCKED per your output contract.
```

Wait for LineRipper's announcement.

### Phase 8: Handle Code Result

Parse the announced result for `POWDERLINE_PR_READY` or `POWDERLINE_CODE_BLOCKED`.

**If PR_READY:**
- Update `run.json` status to `pr-ready`.
- Apply or recommend `agentops:pr-ready` label on the issue.
- Report the PR URL and verification summary to the user.

**If CODE_BLOCKED:**
- Update `run.json` status to `code-blocked`.
- Apply or recommend `agentops:blocked` label.
- If `HumanReview: true`, also apply `agentops:needs-human-review`.
- Report the block reason to the user.

## Safety Rules

These are hard rules. Do not override them.

- Never auto-merge PRs.
- Never force-push.
- Never delete existing worktrees without explicit user instruction.
- Never reset dirty work without explicit user instruction.
- Never commit `.powderline/`.
- Never target `main` if milestone rules prohibit it.
- Never perform production deploys.
- Never rotate secrets or publish packages/releases.
- Stop and escalate on security, privacy, destructive migration, or unclear product behavior.

## Label Reference

See `references/labels.md` for the full label vocabulary:
- `agentops:plan-ready` — plan complete
- `agentops:pr-ready` — PR opened
- `agentops:blocked` — workflow stopped
- `agentops:needs-human-review` — human judgment required
