# AIF package — reference

The **[AI Factory](https://github.com/lee-to/ai-factory) (AIF)** workflows as
MAIster flows, backed by a vendored AIF skills + subagents bundle.
Package source: [`packages/aif/`](../../packages/aif/) ·
quick-start: [`packages/aif/README.md`](../../packages/aif/README.md) ·
design note for the v3 line:
[`specs/2026-09-14-aif-v3-design.md`](specs/2026-09-14-aif-v3-design.md).

- **Provenance:** AI Factory `2.19.0` (git tag `2.19.0`, Apache-2.0); skills
  (incl. their `tests/`) + subagents vendored under `packages/aif/capability/`
  with two MAIster patches (`maister:output` routing block in `aif-review`,
  `model: opus` for the Explore subagents in `aif-plan` / `aif-fix` and for
  the `commit-preparer`, `docs-auditor`, `loop-critic`, `loop-orchestrator`
  subagents).
  Originally extracted from the MAIster repo (`plugins/aif @ maister@c104f66b`,
  2026-06-12).
- **Pin:** git tag `aif/vX.Y.Z` (current line `aif/v3.0.0`).

## Flows

| flow id | Shape | route_when |
| ------- | ----- | ---------- |
| `aif-dev` | intake(form) → plan_consensus(claude + codex drafts, cross-verified, synthesized) → plan → improve → plan_review⛛ → implement → checks → code_review(judge) → cross_review(judge, codex) → review⛛ → commit; checks "fail" / judge / cross-review "fix" → fix → checks; human rework → fix; takeover → checks | A feature/enhancement/refactor that deserves a second independent opinion on the plan and the diff. |
| `aif-dev-light` | intake → plan (emits the Plan-review pair itself) → plan_review⛛ → implement → checks → code_review(judge) → review⛛ → commit; judge "fix" → fix → checks; human rework → fix; takeover → checks | A small/clear feature on one agent. |
| `aif-autonomous` | intake → plan → implement → checks → code_review(judge) → cross_review(judge, codex) → commit; loop exhaustion → escalation⛛ | A well-specified task delivered without mid-flow reviews. |
| `aif-bugfix` | fix → checks → code_review(judge) → cross_review(judge, codex) → review⛛ → commit; judge/cross-review "fix" → fix; emits a self-improvement patch | A reported bug/error/regression. |
| `aif-evolve` | evolve → review⛛ → commit (mutation gate on `.ai-factory/**`,`.claude/**`) | Periodic: distill fix-patches into better skills. |
| `aif-roadmap` | roadmap → review⛛ → commit (mutation gate on `.ai-factory/**`) | A large/multi-milestone initiative needing a roadmap. |
| `aif-init` | setup → architecture → review⛛ → commit (mutation gate) | One-time: project not yet AIF-initialized. |
| `aif-loop` | intake(form) → loop → review⛛ | A single non-code artifact iterated against quality criteria. |
| `aif-qa` | qa → review⛛ | An implemented branch needing change summary + test plan + test cases. |

⛛ = `human` HITL gate. Each agent node maps to an AIF slash-command skill
(`/aif-plan full`, `/aif-improve`, `/aif-implement`, `/aif-verify`,
`/aif-review`, `/aif-fix`, `/aif-commit`, `/aif-evolve`, `/aif-roadmap`,
`/aif`, `/aif-architecture`, `/aif-loop`, `/aif-qa --all`).

## What the prompts encode (v3)

Distilled from the flow owner's MAIster working sessions (2026-07 → 2026-09):

- **Planning is SDD-driven**: API contracts, DB migrations (SQL + journal +
  snapshot), ADR / system-analytics docs and numbered artifacts are plan
  tasks, not follow-ups; the plan is checked for completeness, consistency,
  logical holes, concrete expectations and acceptance criteria. A terse task
  intent in any language is restated as an English `## Requirements Brief`
  next to the verbatim `## Original Request`.
- **Implementation is TDD**: RED → GREEN → refactor per task; tests cover
  required behavior and edge cases with minimum overlap and no trivial tests,
  against real seams; SOLID / KISS / DRY and project conventions; surgical
  diffs; docs in the same increment; commits at checkpoints.
- **Verification never weakens a suite**: failures are classified obsolete
  (delete) or broken (fix); counts, not adjectives. `checks` routes on its
  own `status` (`schemas/verify-outcome.json`): `fail` → `fix`, so a red
  gate can never reach the reviewers unaddressed.
- **Both reviews cover the whole branch over the base branch**: specs and
  analytics completeness, logical holes and consistency, clear expectations,
  contracts and acceptance criteria, test coverage / triviality / overlap, UX
  maturity, code quality, functionality readiness, spec–contract consistency,
  SOLID / KISS / DRY, conventions. The codex `cross_review` (aif-dev,
  aif-autonomous, aif-bugfix) is adversarial and its findings are verified
  by `fix` before anything changes — two different agents review so that
  findings actually get produced.
- **One ACP session per phase**: planning, implementation, verification (+
  judge), cross-review, fix and commit never share a session.
- **Unattended contract instead of "do NOT ask"**: planning, implementation
  and fix nodes run the skills in their own Handoff mode (`HANDOFF_MODE=1`,
  prepared branch → plan named after the branch, no interactive prompts, no
  Handoff MCP); `aif-verify` / `aif-review` / `aif-commit` get their questions
  answered in the prompt. Every node states where human input enters (form
  intake, plan review, human review), records assumptions in its artifact,
  and turns blocking choices into typed Plan-review decisions written in the
  project's `language.ui` (PlanReviewV1 shape given in the prompt). Note:
  the prepared-branch contract force-disables `workflow.plan_id_format:
  sequential` for plans these flows write — they are named after the run
  branch, which is how the consuming skills find them.

## Capability bundle

`capability/` carries the vendored AIF **skills** (`skills/aif-*/SKILL.md` +
`references/` + `tests/` + `templates/` + `scripts/`) and **subagents**
(`agents/*.md` — the loop-*, plan-*, implement-* orchestration agents AIF
skills dispatch via the Task tool). MAIster materializes the whole tree into
each session worktree's `.claude/` at launch; a codex session receives the
skills through its composed `CODEX_HOME` (subagents stay claude-only).

A consuming project registers it as one shared `capability_imports` bundle
(reused by all nine flows) plus the `flows[]` sources, or as one `packages[]`
entry.

## Reconciliation with MAIster

- **Git ownership.** MAIster writes `git.enabled: true`,
  **`git.create_branches: false`** and `git.base_branch` into the run
  worktree's `.ai-factory/config.yaml` (skip-worktree, never committed):
  MAIster owns the worktree and branch, so AIF works git-aware but must not
  create its own branch. `config/ai-factory.config.yaml` (regenerated from
  the 2.19.0 template with the same overrides) is the reference a project
  copies to set language and paths. All committing is deferred to
  `/aif-commit` on the terminal `commit` node; push, merge and promotion stay
  with MAIster.
- **Interactivity → HITL.** Preferences (`form`), plan decisions (typed
  `plan_review`), review verdicts (`human`) and tool permissions are delivered
  by MAIster-native HITL; the AIF `AskUserQuestion` tool is disabled by the
  adapter, so agent nodes run unattended under the contract above.
- **Language.** Plans, decisions and reports follow the project's
  `language.ui` / `language.artifacts` — set them to `ru` for Russian output;
  the flow prompts themselves stay English.
- **Init ordering.** Run `aif-init` first if the project has no
  `.ai-factory/DESCRIPTION.md`; the other flows assume an initialized AIF
  project.

## Policies & gates

- Runner profiles are **intent only**: `primary` = `capability_agent: claude`,
  `effort: high` (implementation, verification, fix, commit); `planner` =
  same intent as a separate slot for planning, consensus drafting and
  synthesis — bind it to the strongest model on the host (a fable-class
  runner); `independent` = `capability_agent: codex`, `effort: high`
  (`aif-dev`, `aif-autonomous`, `aif-bugfix`). No model/adapter pin — the
  running MAIster instance binds each slot (exact intent match, else the
  project's default runner of that capability, else an explicit per-project
  binding).
- `compat.engine_min`: `3.8.0` for `aif-dev` (consensus prompt rendered with
  the run context for the drafters), `3.7.0` for `aif-dev-light`,
  `aif-autonomous`, `aif-bugfix` (artifact injection, typed Plan-review,
  `reentry`); `2.0.0` for `aif-evolve`, `aif-roadmap`, `aif-init`,
  `aif-loop`, `aif-qa`. `defaults.session_policy: resume`.
- `reentry: checks` on the four delivery flows — an operator rework claim
  (ADR-160) re-verifies and re-reviews before commit.
- Sessions (ADR-114): `planning` on `planner` (dev, dev-light, autonomous);
  `implement` / `verify` / `fix` / `commit` on `primary`; `cross` on
  `independent` (dev, autonomous, bugfix). No two phases share a session.
- `retry_policy` on every `ai_coding` node (auto-retry `SPAWN`,
  `EXECUTOR_UNAVAILABLE`, `CHECKPOINT`, `ACP_PROTOCOL`;
  `rewind-to-node-checkpoint`).
- `plan_consensus` (`aif-dev`): `workspace.mode: repo_read`, five material
  axes (`intent_and_acceptance_criteria_explicit`,
  `contracts_migrations_docs_covered`, `task_breakdown_complete_and_ordered`,
  `no_logical_holes`, `scope_minimal_and_complete`), `rounds: iterate, max 2`,
  `on_no_consensus: escalate`, synthesizer `planner`; outputs `consensus_plan`
  (plan) + `debate_log` (human_note); `plan` consumes `consensus_plan` inline.
- Loops: `checks` (`maxLoops: 2`, `output.status` `pass|warn|fail`,
  `on_mismatch: retry`), `code_review` (`maxLoops: 5`; `3` in bugfix) and
  `cross_review` (`maxLoops: 3`) route on their structured output
  (`schemas/verify-outcome.json`, `schemas/review-outcome.json`) and inject
  their `review_comments` into the shared `review_comments` var (the engine
  injects `vars[commentsVar]`, so the var name must equal the output key);
  cross-review findings carry a `[cross-review]` marker. `maxLoops` counts
  visits, so each judge rework opens a fresh epoch for the nodes it re-drives
  (`resetTargets`: code_review → checks; cross_review → checks, code_review;
  human review → all three). Exhaustion routes to the human `review`
  (`escalation` in autonomous).
- `verdict_calibration.confidence_min: 0.7` (advisory `ai_judgment` review
  gate). Human review rework offers `[keep, rewind-to-node-checkpoint]`,
  `maxLoops: 3`; `review` adds a `takeover` decision (returns at `checks`).
- **Artifacts:** `consensus_plan` / `debate_log` (aif-dev), `plan-document` /
  `plan-review` (typed Plan-review), `impl-diff` (diff, requiredFor
  `[review, merge]`), `aif-gate-result` (test_report), `patch` (bugfix).
- **Gates:** `review` — blocking `artifact_required(impl-diff)` + advisory
  `ai_judgment`; `commit` — blocking `command_check` (clean tree + conventional
  last commit); meta-flow commit nodes add `artifact_required` `must_touch`
  mutation gates (`mutation_report`).
