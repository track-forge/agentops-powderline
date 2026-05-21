# Milestone Rules

Powderline supports an optional `## Powderline Rules` section in GitHub milestone descriptions. When present, these rules override defaults for all issues in that milestone.

## Format

The coordinator reads the milestone description and extracts the `## Powderline Rules` section if it exists. Rules are parsed as key-value pairs and bullet lists.

## Supported Fields

- **Base branch** — branch to create issue worktrees from
- **PR target** — branch that PRs should target
- **Issue branch pattern** — naming template for issue branches (supports `{issue_number}` and `{slug}`)

## Supported Rule Entries

Freeform rules under a `Rules:` bullet list. Common rules:
- One issue per PR
- Do not target `main`
- Do not merge automatically

## Supported Label Overrides

Custom label names under a `Labels:` bullet list:
- Plan ready label
- PR ready label
- Blocked label
- Human review label

If no label overrides are specified, the defaults from `references/labels.md` are used.

## Example Milestone Description

```md
## Powderline Rules

Base branch: `milestone/content-makeover`
PR target: `milestone/content-makeover`
Issue branch pattern: `issue/{issue_number}-{slug}`

Labels:
- Plan ready: `agentops:plan-ready`
- PR ready: `agentops:pr-ready`
- Blocked: `agentops:blocked`
- Human review: `agentops:needs-human-review`

Rules:
- One issue per PR.
- Do not target `main`.
- Do not merge automatically.
- If product, UX, architecture, or security judgment is needed, stop and apply `agentops:needs-human-review`.
```

## When No Rules Are Present

If the milestone has no `## Powderline Rules` section, the coordinator uses these defaults:
- Base branch: repo default branch (usually `main`)
- PR target: same as base branch
- Issue branch pattern: `issue/{issue_number}-{slug}`
- Labels: standard agentops labels

The coordinator should note in `mission.md` that no milestone rules were found and defaults are being used.
