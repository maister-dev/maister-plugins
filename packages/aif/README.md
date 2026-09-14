# AIF Flow package

The **AI Factory (AIF) flow package for MAIster**. A self-contained plugin
that wraps the [AI Factory](https://github.com/lee-to/ai-factory/tree/2.x)
agent workflows (plan, implement, review, fix, evolve, roadmap, init) as
MAIster flows backed by a shared skills + subagents bundle.

This package is self-contained; nothing here imports from MAIster core.
Versioned by per-package git tags: `aif/vX.Y.Z` (see the repo root README).

## What changed in `aif/v3.0.0`

A major bump: the engine floor of the delivery flows moves to **3.7.0**
(**3.8.0** for `aif-dev`), the
vendored bundle moves to upstream **ai-factory 2.19.0**, and `aif-dev`,
`aif-autonomous` and `aif-bugfix` now need two coding agents. Design note:
[`docs/aif/specs/2026-09-14-aif-v3-design.md`](../../docs/aif/specs/2026-09-14-aif-v3-design.md).

- **Upstream refresh 2.14.0 → 2.19.0** (skills + subagents vendored from the
  `2.19.0` git tag, incl. skill `tests/`): `aif-plan` gains `ultra` mode, the
  verbatim `## Original Request` section and `## Requirements Reconciliation`
  gates; `aif-fix` is regression-first; new skills `aif-qa-check`,
  `aif-transfer`, `aif-warmup`; `aif-loop` active-time budget. The two MAIster
  patches are re-applied on top: the `maister:output` routing block in
  `aif-review`, and `model: opus` for the Explore subagents in `aif-plan` /
  `aif-fix` and for the `commit-preparer`, `docs-auditor`, `loop-critic`,
  `loop-orchestrator` subagents. `config/ai-factory.config.yaml` is
  regenerated from the 2.19.0 template with the same git overrides.
- **Review by two different agents.** After the claude judge (`code_review`)
  a `cross_review` judge on the `independent` (codex) runner runs an
  adversarial second review in `aif-dev`, `aif-autonomous` and `aif-bugfix`;
  its findings travel in the shared `review_comments` under a `[cross-review]`
  marker and are verified by the `fix` node before anything changes. A human
  rework re-baselines both loops.
  `aif-dev-light` stays single-agent by design.
- **`aif-dev` plans by consensus.** A `plan_consensus` node fans out read-only
  plan drafts to `planner` (claude) and `independent` (codex), cross-verifies
  them on five material axes, and synthesizes one agreed plan; `plan`
  materializes it (inline artifact injection) through `/aif-plan full`.
- **One ACP session per phase, everywhere.** Planning (`planning` session on
  the `planner` slot), implementation, verification (+ judge), cross-review,
  fix and commit never share a session; `aif-bugfix` gets the same split.
- **Prompts rewritten around what the flow owner actually asks for**
  (distilled from ~50 MAIster working sessions): planning is SDD-driven — API
  contracts, DB migrations (SQL + journal + snapshot), ADR/system-analytics
  docs, numbered artifacts, completeness/consistency/logical-holes checks,
  concrete acceptance criteria; implementation is TDD (RED → GREEN →
  refactor, no trivial or overlapping tests, real seams), consistent with the
  specs, SOLID/KISS/DRY, surgical; verification never weakens a suite; both
  reviews cover the whole branch over the base branch across specs, analytics,
  contracts, tests, UX maturity, code quality and conventions. A terse task
  intent in any language is restated as an English `## Requirements Brief`.
- **"Do NOT ask" instructions removed.** Planning, implementation and fix
  nodes drive the skills through their own **Handoff mode** (`HANDOFF_MODE=1`,
  prepared branch): the skills know an orchestrator owns the branch, skip
  their interactive prompts and Handoff MCP calls, and name the plan after
  the branch so `/aif-improve`, `/aif-implement` and `/aif-verify` find it.
  Skills without a Handoff mode (`aif-verify`, `aif-review`, `aif-commit`) get
  their questions answered in the node prompt. Every node states where human
  input enters, assumptions are recorded in the artifact, and blocking choices
  become typed Plan-review decisions (written in the project's `language.ui`,
  with the strict PlanReviewV1 shape spelled out in the prompt).
- **Runner intent only, three slots.** Profiles declare `capability_agent` +
  `effort`; no model or adapter pin — the running MAIster instance binds each
  slot. `primary` (claude) runs implementation, verification, fix and commit;
  `planner` (claude) is a separate slot so a project can bind its strongest
  model (a fable-class runner) to planning, consensus drafting and synthesis;
  `independent` (codex) is the second agent.
- **`aif-bugfix` modernized**: judge `decide` fix loop (`maxLoops: 3`,
  exhaustion → human) plus the codex `cross_review`, `takeover` decision,
  regression-first prompt, per-phase sessions.
- **`reentry: checks`** on `aif-dev`, `aif-dev-light`, `aif-autonomous`,
  `aif-bugfix` (ADR-160 rework claims re-verify before commit).
- Engine floors: `aif-dev` `3.8.0` — the engine that renders a consensus
  node's `prompt` with the run context (`{{ task.prompt }}`, intake vars)
  before the drafts launch; below it the drafters would receive the literal
  template text. `aif-dev-light`, `aif-autonomous`, `aif-bugfix` `3.7.0`;
  `aif-evolve`, `aif-init`, `aif-roadmap`, `aif-loop`, `aif-qa` keep `2.0.0`
  (profile/prompt edits only).

## What changed in `aif/v2.6.0`

Wraps the four flows the original package design deferred (§10 of the
2026-06-08 design): `aif-dev-light` (aif-dev without the `/aif-improve` pass —
`plan` emits the typed Plan-review pair itself, floor `3.1.0`),
`aif-autonomous` (front-loaded intake, no human nodes on the happy path,
loop-exhaustion escalation hatch, floor `2.1.0`), `aif-loop` (the `/aif-loop`
Reflex Loop as a flow: intake budget/criteria → loop → human review, floor
`2.0.0`), and `aif-qa` (`/aif-qa --all` pipeline → human review, floor
`2.0.0`). Adds `schemas/loop-intake.json`.

## What changed in `aif/v2.5.0`

Adds typed Plan-review artifacts and declarative review decisions. `aif-dev`
now requires `compat.engine_min: 3.1.0`; `aif-bugfix`, `aif-evolve`,
`aif-roadmap`, and `aif-init` retain their `2.0.0` floor.

## What changed in `aif/v2.4.0`

Moves the AIF form schemas to package-root `schemas/`, which is the MAIster
package contract. The `aif-dev` flow keeps canonical
`./schemas/<name>.json` references; MAIster materializes those shared files into
the flow revision at install time.

## Provenance

- **Extracted from the MAIster repo** (`plugins/aif` @ `maister@c104f66b`,
  2026-06-12); history prior to extraction lives there.
- **Framework**: AI Factory `2.19.0` (git tag `2.19.0`) —
  https://github.com/lee-to/ai-factory/tree/2.19.0
  (Apache-2.0). Its skills and subagents are vendored under `capability/`
  with two MAIster patches (see the `v3.0.0` notes).
- **Dev workflow**:
  https://github.com/lee-to/ai-factory/blob/2.x/docs/workflow.md
- **Config reference**:
  https://github.com/lee-to/ai-factory/blob/2.x/docs/configuration.md

## Flows

Nine flows ship with this package, each routed by what the incoming task is.

| flow id          | route_when                                                                                     |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| `aif-dev`        | A feature / enhancement / refactor that deserves a second agent: consensus planning (claude + codex) → plan → improve → plan review → TDD implement → verify → judge review → codex cross-review → human review → commit. |
| `aif-dev-light`  | A small/clear feature on one agent — `aif-dev` minus consensus, `/aif-improve` and cross-review. |
| `aif-autonomous` | A well-specified task to deliver end-to-end without mid-flow reviews; questions front-loaded.   |
| `aif-bugfix`     | A reported bug / error / regression: regression-first fix → verify → judge fix loop → human review → commit; emits a self-improvement patch. |
| `aif-evolve`     | Periodic maintenance: distill accumulated fix-patches into better skills (not feature work).    |
| `aif-roadmap`    | A large / multi-milestone initiative needing a roadmap before planning.                         |
| `aif-init`       | One-time: project not yet AIF-initialized (`/aif` + `/aif-architecture`).                       |
| `aif-loop`       | A single non-code artifact iterated against quality criteria (`/aif-loop` Reflex Loop).         |
| `aif-qa`         | An implemented branch needing change summary + test plan + test cases (`/aif-qa --all`).        |

Flow sources live under `flows/<id>/flow.yaml`.

## Package layout

| Path                          | Purpose                                                                 |
| ----------------------------- | ----------------------------------------------------------------------- |
| `capability/`                 | Shared bundle — vendored AIF skills (`skills/`) + subagents (`agents/`). |
| `schemas/`                    | Shared form schemas: `intake.json`, `review-outcome.json`, `loop-intake.json`. |
| `flows/<id>/flow.yaml`        | The 9 flow sources listed above.                                        |
| `config/ai-factory.config.yaml` | Default `.ai-factory/config.yaml` template for a consuming project.    |
| `setup.sh`                    | Inert no-op (see below).                                                |

## What changed in `aif/v2.1.0`

Adopts the MAIster **flow engine 2.0.0** baseline (M42 / ADR-114 — unified
runner config + first-class sessions):

- `compat.engine_min: 2.0.0` on all five flows.
- **`aif-dev` first-class sessions** — the single reused agent context is split
  into fresh-context phases at meaningful boundaries: `implement`, `verify`
  (checks + code_review), `fix`, and `commit` each run as their own ACP session,
  while planning (`plan`, `improve`) stays on the implicit `default` session.
  State flows between phases through the typed artifacts (impl-diff, gate
  result), not session memory. The `review → fix` rework loop re-enters `fix` on
  a fresh session each iteration (`session_policy: new_session`).
- Every session **inherits the flow's one `claude-code` runner** — these are
  context resets, not new runners.
- `aif-bugfix`, `aif-evolve`, `aif-roadmap`, `aif-init` keep their single reused
  `default` session (engine-baseline bump only).

## What changed in `aif/v2.0.0`

Engine-feature bump applied at extraction (vs the `local-dev` package that
shipped inside the MAIster repo):

- `compat.engine_min: 1.4.0` on all five flows.
- Explicit `defaults: { session_policy: resume }` (M30/ADR-081).
- `retry_policy` on every `ai_coding` node — auto-retry of infra failures
  (`SPAWN`, `EXECUTOR_UNAVAILABLE`, `CHECKPOINT`, `ACP_PROTOCOL`), workspace
  rewound to the pre-attempt checkpoint (M30/ADR-080).
- Review→fix rework loops (`aif-dev`, `aif-bugfix`) offer the reviewer
  `workspacePolicies: [keep, rewind-to-node-checkpoint]` (M30/ADR-079).
- File-edit gates (M29/ADR-074) on the `commit` node of the meta-flows:
  `aif-evolve` / `aif-init` must touch `.ai-factory/**` or `.claude/**`,
  `aif-roadmap` must touch `.ai-factory/**` — blocking `artifact_required`
  gates with `must_touch` + a recorded `mutation_report` artifact. The gate
  sits on the commit node because AIF defers all committing to `/aif-commit`
  (mutation ranges are committed-only).
- `maister-package.yaml` added — the package manifest for MAIster package
  management (single-import). `must_not_touch` protection zones are
  deliberately deferred to a later release: they need restriction capability
  records, which packages can ship only once MAIster typed ingestion lands.

## How MAIster consumes it

A consuming project's `maister.yaml` registers this package twice over:

- **One shared `capability_imports` bundle** pointing at `capability/`.
  All nine flows reuse the same vendored skills + subagents instead of each
  carrying their own copy. MAIster materializes these into the workspace
  (per ADR-043) — there is no `ai-factory init` and no npm install.
- **Nine `flows[]` sources**, one per `flows/<id>/flow.yaml` above. Each flow
  resolves its steps against the shared capability bundle.

MAIster writes the `git` overrides (`enabled: true`, `create_branches:
false`, `base_branch`) into the run worktree's `.ai-factory/config.yaml`
itself (skip-worktree, never committed) — **MAIster owns the worktree and
branch**, so AIF must not create its own. `config/ai-factory.config.yaml` is
the reference template for a project's own config (language, paths,
workflow); copy it into the project to change `language.ui` /
`language.artifacts` or the plan-file format.

Interactivity (preferences, approvals, review gates, typed plan decisions) is
delivered by **MAIster-native HITL** (form / human / permission steps), not the
AIF `AskUserQuestion` tool (the adapter disables it). Every agent node runs
unattended: its prompt says where human input enters, tells the agent to
record assumptions in the artifact, and routes blocking choices into the typed
Plan-review decisions. Artifact and question language follow the project's
`.ai-factory/config.yaml` (`language.ui` / `language.artifacts`) — set both to
`ru` for Russian plans and decisions; no separate package is needed.

`aif-dev`, `aif-autonomous` and `aif-bugfix` need a host runner for BOTH
`claude` and `codex`; `aif-dev-light` and the meta flows need `claude` only.
Bind the `planner` slot to your strongest model.

> **Run the `aif-init` flow first** if the project has no
> `.ai-factory/DESCRIPTION.md`. The other flows assume an initialized AIF
> project (description + architecture present).

## setup.sh

`setup.sh` is an **inert no-op**: it prints a one-line notice to stderr and
exits `0`. MAIster delivers AIF skills through capability materialization, so
there is nothing to install at flow-setup time.
