# Powderline Mission Packet

## Role

{ROLE_DESCRIPTION}

## Objective

{OBJECTIVE_DESCRIPTION}

## Repository

- GitHub repo: `{GITHUB_ORG}/{REPO_NAME}`
- Issue: `#{ISSUE_NUMBER}`
- Issue URL: `https://github.com/{GITHUB_ORG}/{REPO_NAME}/issues/{ISSUE_NUMBER}`
- Milestone: `{MILESTONE_NAME}`
- Local base clone: `{LOCAL_CLONE_PATH}`
- Issue worktree: `{WORKTREE_PATH}`

## Workspace

- Worktree root: `{WORKTREE_PATH}`
- Mission file: `{WORKTREE_PATH}/.powderline/mission.md`
- Plan file: `{WORKTREE_PATH}/.powderline/plan.md`
- Run metadata: `{WORKTREE_PATH}/.powderline/run.json`

## Issue Context

### Title

{ISSUE_TITLE}

### Labels

{ISSUE_LABELS}

## Milestone Context

{MILESTONE_SUMMARY}

## Powderline Rules Observed

- Base branch: `{BASE_BRANCH}`
- PR target: `{PR_TARGET}`
- Issue branch pattern: `{BRANCH_PATTERN}`
{ADDITIONAL_RULES}

## Raw Milestone Description

{RAW_MILESTONE_DESCRIPTION}

## Repo Powderline Config

{POWDERLINE_MD_CONTENTS_OR_NONE}

## Raw Issue Body

{RAW_ISSUE_BODY}

## Relevant Issue Comments

{ISSUE_COMMENTS}

## Required RouteFinder Output

Write the plan to:

`{WORKTREE_PATH}/.powderline/plan.md`

Then return either:

`POWDERLINE_PLAN_READY`

or:

`POWDERLINE_PLAN_BLOCKED`

See the output contract in RouteFinder's AGENTS.md for the full structured format.

## Required LineRipper Output

When invoked later, LineRipper must read:

- `.powderline/mission.md`
- `.powderline/plan.md`

Then return either:

`POWDERLINE_PR_READY`

or:

`POWDERLINE_CODE_BLOCKED`

See the output contract in LineRipper's AGENTS.md for the full structured format.

## Safety Rules

- Do not commit `.powderline/`.
- Do not target `main` if milestone rules prohibit it.
- Do not force-push.
- Do not merge PRs.
- Do not perform production deploys.
- Do not rotate secrets or publish packages.
- Escalate with `agentops:needs-human-review` for product, UX, security, privacy, migration, or architecture uncertainty.
