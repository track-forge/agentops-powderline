# Workspace Layout

## Canonical Clone

Resolve one clone for the target GitHub repository before fetching, creating a
worktree, or running repo hooks. Use the first applicable source:

1. The local clone explicitly selected by the requester for this run.
2. The coordinator workspace's documented canonical clone for this exact
   `owner/repo` (for example, in its `AGENTS.md`). Resolve documented relative
   paths against the workspace, not the current working directory.
3. If neither source specifies a path, use `~/repos/{org}/{repo}`. Clone the
   target there only if that fallback path does not exist.

Expand and resolve the selected path to an absolute path. Check that it is the
root of a Git working tree, not a subdirectory or bare repository, and that
`origin` identifies the requested GitHub host and exact `owner/repo`. Compare
repository identity rather than raw URL strings: HTTPS and SSH forms (including
an explicit SSH port), with or without a trailing `.git`, can refer to the same
repo. Don't match by repository basename alone.

If a selected path is missing, invalid, ambiguous, or points to another repo,
report the blocker and do not try another path or clone a duplicate. When
resuming a known run, validate its recorded clone and worktree against the target
and continue in place. If the recorded path conflicts with the selected clone,
report both paths instead of starting a second worktree for that run.

## Issue Worktrees

Each issue gets a dedicated Git worktree under the resolved clone:

```
{local_clone}/.worktrees/issue-{issue-number}/
```

Record the absolute clone and worktree paths in the mission and `run.json`.
Pass the same worktree path to every worker; workers do not resolve or clone
the repo independently.

Worktree directory names are deterministic and simple. Do not include milestone names or slugs in worktree paths.

## Powderline Directory

Each issue worktree has a `.powderline/` directory for run artifacts:

```
.powderline/
  mission.md      # coordinator writes this
  recon.md        # Scout writes this
  plan.md         # RouteFinder writes this
  run.json        # coordinator writes and updates this
```

Full path example:

```
{worktree}/.powderline/mission.md
{worktree}/.powderline/recon.md
{worktree}/.powderline/plan.md
{worktree}/.powderline/run.json
```

## Git Exclude Rules

`.powderline/` must never be committed. Add it to local git excludes:

```bash
echo ".powderline/" >> .git/info/exclude
```

Do not modify the repo's committed `.gitignore` unless explicitly instructed by the user.

## Worktree Reuse

If an issue worktree already exists:

1. Inspect the current branch.
2. Run `git status --short`.
3. Ignore `.powderline/` files when checking status.
4. If unrelated dirty files exist, stop and report blocked.
5. If the worktree belongs to the same issue, reuse it.
6. Never delete or reset an existing worktree without explicit user instruction.
