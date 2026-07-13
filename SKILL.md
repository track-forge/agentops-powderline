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
5. Add `.powderline/` and `.env.local` to `.git/info/exclude` if not already present.
6. If `.powderline.init.sh` exists in the worktree root, run it:
   ```bash
   cd {worktree} && bash .powderline.init.sh
   ```
   If it exits non-zero, stop and report `agentops:blocked` with the output.
7. If `POWDERLINE.md` exists in the worktree root, read it and include relevant context in the mission packet.

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

Comment on the issue to signal work has started:

```bash
gh issue comment {issue_number} --repo {org}/{repo} --body "Powderline picked up this issue. RouteFinder is planning the implementation."
```

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
- RouteFinder already labeled the issue `agentops:plan-ready`.
- Proceed to Phase 7.

**If PLAN_BLOCKED:**
- Update `run.json` status to `plan-blocked`.
- RouteFinder already labeled the issue `agentops:blocked`.
- If `HumanReview: true`, also apply `agentops:needs-human-review`:
  ```bash
  gh issue edit {issue_number} --repo {org}/{repo} --add-label "agentops:needs-human-review"
  ```
- Comment on the issue with the block reason:
  ```bash
  gh issue comment {issue_number} --repo {org}/{repo} --body "Powderline blocked during planning: {reason}"
  ```
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
- LineRipper already labeled the issue `agentops:pr-ready`.
- Comment on the issue with the PR link:
  ```bash
  gh issue comment {issue_number} --repo {org}/{repo} --body "Powderline opened a PR: {pr_url}"
  ```
- Proceed to Phase 9.

**If CODE_BLOCKED:**
- Update `run.json` status to `code-blocked`.
- LineRipper already labeled the issue `agentops:blocked`.
- If `HumanReview: true`, also apply `agentops:needs-human-review`:
  ```bash
  gh issue edit {issue_number} --repo {org}/{repo} --add-label "agentops:needs-human-review"
  ```
- Comment on the issue with the block reason:
  ```bash
  gh issue comment {issue_number} --repo {org}/{repo} --body "Powderline blocked during implementation: {reason}"
  ```
- Report the block reason to the user.

### Phase 9: Run the CI Repair Loop

The repair loop is optional. Skip it when the mission explicitly disables CI repair or the PR has no checks. Otherwise, inspect the PR checks after LineRipper opens the PR:

```bash
gh pr checks {pr_number} --repo {org}/{repo}
```

Use a maximum of **two repair attempts** unless the mission specifies a lower limit. Never use an unbounded retry loop.

For each attempt with failing checks:

1. Update `run.json` status to `ci-repairing` and record `ci_repair_attempt`.
2. Capture the failing run details and logs:
   ```bash
   gh run view {run_id} --repo {org}/{repo} --log-failed
   ```
3. Re-spawn LineRipper in CI repair mode on the existing issue worktree and PR branch:
   ```
   sessions_spawn:
     agentId: "lineripper"
     context: "isolated"
     task: |
       You are LineRipper operating in CI_REPAIR mode. Read your SOUL.md and AGENTS.md.

       Mission: {worktree}/.powderline/mission.md
       Plan: {worktree}/.powderline/plan.md
       Worktree: {worktree}
       PR: {pr_url}
       Repair attempt: {attempt} of {max_attempts}
       Failing CI evidence: {run_ids_and_failed_jobs}

       Inspect the failed logs, apply only the minimal targeted fix, run the relevant
       checks locally, commit, and push normally. Do not force-push or broaden scope.

       Return POWDERLINE_CI_REPAIRED or POWDERLINE_CI_BLOCKED per your output contract.
   ```
4. Wait for CI to complete again and re-check status.

Stop the loop immediately when checks pass. Record `ci_repair_attempts`, the repair commit SHA(s), and `ci_status: passed` in `run.json`, then proceed to Phase 10.

If LineRipper reports blocked, or checks still fail after the final attempt:

- Update `run.json` status to `ci-blocked` and record the failing checks.
- Apply `agentops:blocked` and, when `HumanReview: true`, `agentops:needs-human-review`.
- Comment on the issue with the last failing check and repair attempts.
- Report the block to the user. Stop here.

### Phase 10: Spawn RouteFinder for Plan-Aware Review

The review pass is optional but enabled by default after the PR is CI-clean. Skip it only when the mission explicitly disables review.

Update `run.json` status to `reviewing`, then spawn RouteFinder in review mode:

```
sessions_spawn:
  agentId: "routefinder"
  context: "isolated"
  task: |
    You are RouteFinder operating in REVIEW mode. Read your SOUL.md and AGENTS.md.

    Mission: {worktree}/.powderline/mission.md
    Original plan: {worktree}/.powderline/plan.md
    Worktree: {worktree}
    PR: {pr_url}
    Base branch: {pr_target}

    Compare the PR diff against the mission and original plan. Identify completed
    items, missed items, scope drift, unintended changes, verification gaps, and risks.
    Write the durable review to {worktree}/.powderline/review.md using the review template.

    Return POWDERLINE_REVIEW_READY or POWDERLINE_REVIEW_BLOCKED per your output contract.
```

### Phase 11: Handle Review Result

**If REVIEW_READY with no blocking findings:**

- Update `run.json` status to `review-ready` and record `review_path`.
- Keep `agentops:pr-ready` applied.
- Report the PR URL, CI evidence, and review summary to the user.

**If REVIEW_READY with blocking findings, or REVIEW_BLOCKED:**

- Update `run.json` status to `review-blocked`.
- Apply `agentops:needs-human-review`.
- Comment on the issue with a concise summary and the local `review.md` path.
- Report the findings to the user. Do not silently send the PR back through implementation; a new repair pass requires explicit coordinator or human direction.

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
- Never exceed the configured CI repair attempt limit.
- Never let the review pass modify code, commits, branches, or the PR.
- Stop and escalate on security, privacy, destructive migration, or unclear product behavior.

## Label Reference

See `references/labels.md` for the full label vocabulary:
- `agentops:plan-ready` — plan complete
- `agentops:pr-ready` — PR opened
- `agentops:blocked` — workflow stopped
- `agentops:needs-human-review` — human judgment required
