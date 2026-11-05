# Runtime Adaptation — portability notes for non-OpenClaw harnesses

Powderline is authored as an OpenClaw skill, but its workflow has no
OpenClaw-specific behavior — only a few coupling points where the harness it
runs on matters. This document is purely additive; it changes nothing about the
workflow in `SKILL.md`, the scripts, or the agent workspaces. OpenClaw users
can ignore it.

## Spawn-primitive mapping

The spawn seams are the six `sessions_spawn` blocks in `SKILL.md` (Soloist
~L73, Scout ~L211, RouteFinder planning ~L250, LineRipper implementation ~L299,
LineRipper CI-repair ~L394, RouteFinder review ~L431). Map their parameters
onto the harness's own spawn primitive:

| `sessions_spawn` field | Adaptation |
|---|---|
| `agentId` | Load the corresponding workspace under `agents/` (`scout`, `routefinder`, `lineripper`, `soloist`) as the spawned agent's persona and instructions. |
| `task` | Becomes the spawn prompt. Keep it self-contained: the `.powderline/` artifact paths, templates, and acceptance criteria must all be in the prompt. |
| `model` | Omit when the harness has no model selection. The workflow already specifies the fallback: "omit `model` and use the model configured for the selected agent." |
| `context: isolated` | Best-effort only. If the harness's spawns inherit the coordinator's context, keep every brief self-contained and never rely on inherited context for the mission, plan, or templates. |

Preserve the leaf-agent rule: spawned agents must not spawn further agents.
The shipped `install.sh` expresses this as `tools.deny: ["sessions_spawn"]` in
the `agents.list[]` entries; an equivalent "max spawn depth 1" restriction on
the harness side works the same way.

## Model-routing opt-out

In the installed copy of `model-routing.yaml`, set `modelRouting.enabled:
false`. This is the supported opt-out; `fallback: existing` then governs, and
the coordinator uses each agent's configured model. `scoutEnabled` and
`scoutMaxBytes` are independent of model selection and still apply. The shipped
`openai-codex/*` identifiers are the OpenClaw profile's examples, not
requirements.

## Install-layout mapping

`scripts/install.sh` is a file copy plus configuration instructions; nothing
about it is OpenClaw-specific except its destination defaults. Map its copies
onto the harness's own layout:

| `install.sh` copies | Meaning for another harness |
|---|---|
| `SKILL.md` + `model-routing.yaml` → skill directory | Install the coordinator workflow and routing config where the harness loads skills. |
| `assets/*`, `references/*` → alongside them | Keep the templates and reference docs resolvable at the relative paths the workflow expects. |
| `agents/<scout\|routefinder\|lineripper\|soloist>/*` → agent personas | Load the SOUL/AGENTS/IDENTITY/TOOLS templates as the four leaf-agent personas. The workspaces themselves are portable; only the `agents.list[]` loading mechanism is OpenClaw-specific. |

The `agents.list[]` JSON the script prints is the declarative meaning: four
agents named `scout`, `routefinder`, `lineripper`, `soloist`, each denied
further spawning. `openclaw.json` registration and `openclaw gateway restart`
are OpenClaw-specific; replace them with the harness's own skill/persona
registration step.

## Backwards compatibility

Nothing in this document alters existing behavior. It only names seams that
already exist in the shipped skill — the documented opt-outs, the parameter
fallbacks in `SKILL.md`, and the copy-plus-config nature of the install — so
non-OpenClaw harnesses can adopt Powderline without forking it.
