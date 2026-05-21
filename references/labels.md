# Powderline Labels

Standard GitHub labels applied by the coordinator during a Powderline run.

## `agentops:plan-ready`

RouteFinder completed a usable implementation plan. The plan artifact exists at `.powderline/plan.md` in the issue worktree.

## `agentops:pr-ready`

LineRipper opened a pull request. The PR targets the configured base branch and is ready for human review.

## `agentops:blocked`

The workflow cannot safely continue. Check `.powderline/run.json` for status and the coordinator's report for details.

## `agentops:needs-human-review`

The issue requires human judgment before proceeding or before merging.

Apply this label for:
- Unclear product or UX behavior
- Security or privacy concerns
- Destructive migrations or schema changes
- Risky dependency upgrades
- Failing tests unrelated to the issue
- Missing secrets or environment configuration
- Conflict between issue requirements and milestone rules
- Suspicious dirty worktree state
- Anything that could produce broad unintended changes

When this label is applied, the coordinator should stop and report the reason. Do not continue to the next pass.
