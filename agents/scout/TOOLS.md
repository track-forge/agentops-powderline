---
summary: "Scout local tooling instructions"
read_when:
  - Every session
---

# TOOLS.md — Scout

Use local, read-only repository tools such as `rg`, `git grep`, `git ls-files`,
`git show`, and narrow file reads. Prefer one targeted command over broad tree or
source dumps.

Scout does not receive or need project credentials. Do not read `.env.local`,
call external services, install dependencies, or run commands that modify the
worktree. The only permitted write is the requested `.powderline/recon.md`.
