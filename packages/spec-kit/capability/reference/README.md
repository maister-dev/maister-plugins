# Spec Kit reference bundle (provenance — NOT materialized)

This bundle is **reference-only**. It is declared as the package's capability
(`spec-kit-reference`) so Spec Kit provenance travels with the package, but it
contains **no `skills/` or `agents/` subtree**, so MAIster's capability
materializer copies nothing into the session worktree. The flows drive Spec Kit
through its `specify` CLI plus the agent-native skills that `specify init`
scaffolds **into the project** (installed by `setup.sh` / the matching init
flow).

Targets `github/spec-kit@v0.10.3` (MIT).

## The phases (and which speckit skill each flow node invokes)

Spec Kit's SDLC is a sequence of agent skills. The Claude integration writes
`.claude/skills/speckit-<name>/SKILL.md` and invokes `/speckit-<name>`. The
Codex integration with `--integration-options="--skills"` writes
`.agents/skills/speckit-<name>/SKILL.md` and invokes `$speckit-<name>`.
Flow YAML stores `@skill:speckit-<name>`; MAIster normalizes that canonical
token to the selected adapter's slash or dollar form at launch.

| phase | Claude / Codex skill | writes |
| ----- | -------------------- | ------ |
| Constitution | `/speckit-constitution` / `$speckit-constitution` | `.specify/memory/constitution.md` |
| Specify | `/speckit-specify` / `$speckit-specify` | `specs/NNN-<slug>/spec.md`, `…/checklists/requirements.md` |
| Clarify | `/speckit-clarify` / `$speckit-clarify` | updates `spec.md` (`## Clarifications`) |
| Plan | `/speckit-plan` / `$speckit-plan` | `plan.md` + `research.md`, `data-model.md`, `contracts/`, `quickstart.md` |
| Tasks | `/speckit-tasks` / `$speckit-tasks` | `tasks.md` |
| Analyze | `/speckit-analyze` / `$speckit-analyze` | read-only Markdown report (no file written) |
| Implement | `/speckit-implement` / `$speckit-implement` | source code; marks `tasks.md` items `[X]` |

Optional phases not yet wired into a flow: `speckit-checklist` and
`speckit-taskstoissues`.

## The SKILL.md frontmatter `specify init` writes

Each scaffolded agent-native `speckit-<name>/SKILL.md` carries frontmatter the
CLI rebuilds per-agent — for example `speckit-plan`:

```yaml
---
name: "speckit-plan"
description: "Execute the implementation planning workflow using the plan template to generate design artifacts."
argument-hint: "Optional guidance for the planning phase"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/plan.md"
user-invocable: true
disable-model-invocation: false
---
```

We do **not** author these — `specify init` does. They are documented here so the
exact invocation surface the flows target is auditable.

## Why these are reference, not live MAIster capabilities

1. **`specify init` writes them into the consuming project.** Claude flows use
   `.claude/skills/speckit-*` committed by `sk-init`; Codex flows use
   `.agents/skills/speckit-*` committed by `sk-init-codex`. MAIster ships
   nothing to materialize.
2. **They assume interactivity.** The specify and clarify skills normally ask
   the user questions. MAIster's unattended development flows instead record
   open questions as `[NEEDS CLARIFICATION: …]` markers, then an authored
   **clarify** human node collects the maintainer's answers and feeds them back
   into the matching agent-native skill.

The `.specify/` scripts, templates, and command bodies live inside the pinned
`spec-kit` wheel (bundled, no network) and are scaffolded by the matching init flow;
they are not re-vendored here.
