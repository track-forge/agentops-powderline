# Workspace Layout

## Host-Level Repo Layout

Target repos are cloned to:

```
~/repos/{github-org}/{repo}/
```

Example:

```
~/repos/track-forge/crucible/
```

## Issue Worktrees

Each issue gets a dedicated git worktree under the repo clone:

```
~/repos/{github-org}/{repo}/.worktrees/issue-{issue-number}/
```

Example:

```
~/repos/track-forge/crucible/.worktrees/issue-44/
```

Worktree directory names are deterministic and simple. Do not include milestone names or slugs in worktree paths.

## Powderline Directory

Each issue worktree has a `.powderline/` directory for run artifacts:

```
.powderline/
  mission.md      # coordinator writes this
  plan.md         # RouteFinder writes this
  run.json        # coordinator writes and updates this
```

Full path example:

```
~/repos/track-forge/crucible/.worktrees/issue-44/.powderline/mission.md
~/repos/track-forge/crucible/.worktrees/issue-44/.powderline/plan.md
~/repos/track-forge/crucible/.worktrees/issue-44/.powderline/run.json
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
