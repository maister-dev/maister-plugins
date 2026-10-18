# Spec Kit Flow package

The **[GitHub Spec Kit](https://github.com/github/spec-kit) spec-driven
workflow for MAIster**. Wraps Spec Kit's SDLC
(**constitution → specify → clarify → plan → tasks → analyze → implement**) as
MAIster flows that drive the `specify` CLI and its agent-native skills for
Claude Code or Codex.

Versioned by per-package git tags: `spec-kit/vX.Y.Z`. The **Spec Kit version is
pinned to `github/spec-kit@v0.10.3`** in `setup.sh` and both init flows'
installer.

## Unreleased

- Adds Codex-native `sk-init-codex` and `sk-dev-codex` flows without changing
  the existing Claude Code flows.
- `sk-init-codex` uses Spec Kit's bundled Codex integration with skills enabled,
  which scaffolds `.agents/skills/speckit-*`; `sk-dev-codex` requires that
  repository-native path and invokes the skills through `$speckit-*` mentions.
- Both Codex flows declare a portable `capability_agent: codex` runner intent
  rather than pinning an adapter, provider, or model.

## What changed in `spec-kit/v1.1.0`

Adopts the MAIster **flow engine 2.0.0** baseline (M42 / ADR-114 — unified
runner config + first-class sessions):

- `compat.engine_min: 2.0.0` on both flows.
- **`sk-dev`** keeps the spec-authoring chain (`specify`, `clarify-apply`,
  `plan`, `tasks`, `analyze`) on the implicit `default` session — each
  `/speckit-*` phase builds on the prior — while `implement` and `code_review`
  run on their own fresh sessions. The `review → implement` rework re-enters
  `implement` fresh each iteration (`session_policy: new_session`). All sessions
  inherit the flow's one `claude-code` runner; state flows through the typed
  artifacts (feature-spec, impl-diff).
- `sk-init` keeps a single reused `default` session (engine-baseline bump only).

## Provenance

- **Framework**: Spec Kit — https://github.com/github/spec-kit (MIT). The
  `specify` CLI is installed at runtime; `specify init` scaffolds Spec Kit's
  `.specify/` base plus Claude Code skills under `.claude/skills/` or Codex
  skills under `.agents/skills/` into the project.
  `capability/reference/` documents the phases + the SKILL.md frontmatter as
  read-only provenance (see `capability/reference/README.md`).

## Flows

| flow id         | HITL | route_when |
| --------------- | ---- | ---------- |
| `sk-dev`        | 2    | Claude Code: build a feature end-to-end: specify → **clarify** → plan → tasks → analyze → implement → code_review → **review** → commit. |
| `sk-init`       | 1    | Claude Code: install the `specify` CLI + scaffold Spec Kit + author the project constitution. Run + promote this first. |
| `sk-dev-codex`  | 2    | Codex: the same end-to-end SDLC, using repository-native `$speckit-*` skills. |
| `sk-init-codex` | 1    | Codex: install the `specify` CLI + scaffold `.agents/skills/speckit-*` + author the project constitution. Run + promote this first. |

Each `sk-dev` variant covers the full recommended Spec Kit SDLC in one flow.

## How Spec Kit is driven (hybrid: `cli` + `ai_coding`)

Spec Kit's creative phases exist as agent skills (there is no headless CLI for
specify/plan/tasks/…), so unlike a CLI-first tool they must run through the
selected coding agent. The flows split work by node type:

- **`cli` / `check` nodes** run deterministically (MAIster's runner, `bash -c`,
  host PATH — no agent, no permission HITL): each init flow's `ensure` (install
  `specify`) + `scaffold` (`specify init`) + `commit`; each development flow's
  existence backstops (`spec-gate` / `plan-gate` / `tasks-gate`), the
  task-completion `verify`, the `clarify-extract` marker dump, and the final
  `commit`.
- **`ai_coding` nodes** use MAIster's canonical `@skill:speckit-*` mentions
  wherever an agent must reason or write. MAIster normalizes them at launch:
  Claude receives `/speckit-*`; Codex receives `$speckit-*`. The nodes carry
  `settings.permissionMode: allow`, so the agent runs unattended — HITL lives
  at the two human gates (clarify, review).

## The `specify` CLI must be present (and how it gets there)

- **`requirements` (ADR-091).** Each development flow checks `command -v
  specify`, `.specify/`, and its own integration directory before creating a
  worktree/session: `.claude/skills/speckit-specify` for `sk-dev`,
  `.agents/skills/speckit-specify` for `sk-dev-codex`. A missing scaffold is a
  clean `PRECONDITION` refusal. The init flows require only `uv|pipx` + `git`.
- **Install + scaffold.** Both init flows ensure the pinned CLI. `sk-init` runs
  `specify init --integration claude`; `sk-init-codex` runs `specify init
  --integration codex --integration-options="--skills"`. Both are fully
  non-interactive and use assets bundled in the wheel. `setup.sh` performs the
  same CLI install at package-install time (exec-trust gated).
- **Sequencing.** Run and promote the init flow matching the intended coding
  agent. The resulting `.specify/` plus agent-native skills must be committed on
  the base branch before the corresponding development flow launches.

## MAIster ↔ Spec Kit reconciliation (in node prompts)

- **Non-interactive.** Spec Kit's specify/clarify skills ask the user clarifying
  questions; interactive questioning is unavailable inside an unattended node.
  Both development flows instead record open questions as
  `[NEEDS CLARIFICATION: …]` spec markers and proceed on best-judgment
  assumptions; the authored **clarify** human node surfaces them and feeds the
  maintainer's answers into the matching agent-native skill.
- **Git/promotion owned by MAIster.** The flows never install Spec Kit's opt-in
  `git` extension (so the specify skill only `mkdir`s the `specs/` dir — never
  `git checkout`/`branch`), and the prompts forbid branch/merge/push/PR. Spec +
  code are committed by the terminal `cli` node; MAIster promotes the branch.
- **CRITICAL blocks implement.** The analyze skill is read-only (writes no
  file), so the `analyze` node resolves CRITICAL cross-artifact inconsistencies
  at source and a **blocking `ai_judgment`** gate enforces "zero CRITICAL
  remaining" before `implement`.

## Policies & gates

- Claude flows retain their `claude-code` runner pin. Codex flows declare the
  portable `codex` capability with high effort and let MAIster bind the host
  runner. All variants use `compat.engine_min: 2.0.0`,
  `defaults.session_policy: resume`, retry policies on every `ai_coding` node,
  and verdict calibration on development flows.
- Gates: existence backstops (`check` nodes) after specify/plan/tasks;
  `analyze` → blocking `ai_judgment` (no CRITICAL); `verify` → `check`
  task-completion (no unchecked `- [ ]`); `review` →
  `artifact_required(impl-diff)` blocking + `ai_judgment` advisory; terminal
  commits → `artifact_required must_touch` (mutation_report) + clean-tree
  `command_check`.

## Requirements

`uv` (or `pipx`) + Python 3.11+ and `git` on the supervisor/web host (`cli`
nodes run on the web tier, the `ai_coding` Bash on the supervisor — co-located
by default). `specify init` needs **no** network (assets are bundled in the
pinned wheel); the one-time CLI install does.

## Out of scope (today)

- One dynamically switching flow ID for both agents. Static Claude and Codex
  variants keep runner intent, scaffold paths, and skill invocation syntax
  explicit and independently preflightable.
- `/speckit-checklist` and `/speckit-taskstoissues` (GitHub issues), and
  spec-only / implement-only flow splits — future additions.
- Dynamic multiple-choice clarification surfaced from the agent (needs core
  MAIster HITL work); the clarify node collects free-text answers.

## Reference-only capability bundle

`capability/` has no `skills/`/`agents/` subtree, so MAIster materializes
nothing from it — it carries Spec Kit provenance only (see
`capability/reference/README.md`).
