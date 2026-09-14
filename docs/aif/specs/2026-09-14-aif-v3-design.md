# aif v3 — design note (2026-09-14)

Why the `aif` package jumped to `aif/v3.0.0`, what was decided, and what is
still open. Companion to the release notes in
[`packages/aif/README.md`](../../../packages/aif/README.md) and the reference in
[`../README.md`](../README.md).

## Inputs

1. The flow owner's request: drop the "do NOT ask" prompt instructions, make
   `/aif-improve` produce SDD-driven plans checked for completeness /
   consistency / logical holes / acceptance criteria, make implementation
   TDD-based, make `/aif-review` cover the whole branch across specs,
   analytics, tests, UX maturity, code quality and conventions, restate a
   terse task intent as an English planning request, consider a Russian
   package, consider codex cross-review and a two-agent consensus planning
   node, refresh the vendored ai-factory, and modernize the flow structure for
   the current engine.
2. An extraction of every user turn from 49 MAIster working sessions
   (2026-07-26 → 2026-09-14, 730 turns). The planning, TDD and review
   phrasings above are the exact strings the owner pasted into
   `/aif-improve`, `/aif-review` and `/codex:adversarial-review` in more than
   a dozen sessions; the observed pipeline is plan → improve → implement →
   verify → review → fix all findings → codex adversarial review → verify and
   fix confirmed findings → commit. Other stable rules: questions only as a
   numbered batch at plan end, each a fork with pros/cons and a recommended
   option; artifacts in English, questions in Russian; a red suite blocks and
   is classified obsolete-or-broken; docs truth pass after the gate; numbered
   artifacts (ADR/migration) rechecked against the base branch; no runner or
   model pins in a flow package ("let the running instance decide").
3. The engine: MAIster `3.7.0` (`consensus` since 1.9.0, artifact body
   injection 2.2.0, typed Plan-review 3.1.0, `reentry` 3.5.0). The vendored
   bundle was upstream ai-factory `2.14.0` + two MAIster patches; upstream is
   at `2.19.0`.

## Decisions

- **D1 — Unattended contract replaces "do NOT ask".** The adapter disables
  `AskUserQuestion`, so a chat question would only end a node's turn early.
  Planning, implementation and fix nodes now drive the skills through their
  own Handoff mode (`HANDOFF_MODE=1`, `HANDOFF_BRANCH_PREPARED=1`, branch =
  the one MAIster checked out): the skills skip their interactive prompts and
  Handoff MCP calls and name the plan after the branch, which is also how
  `/aif-improve`, `/aif-implement` and `/aif-verify` discover it (with
  `create_branches: false` a slug-named plan would be undiscoverable in a
  repo with more than one plan — review finding). Skills without a Handoff
  mode (`aif-verify`, `aif-review`, `aif-commit`) get each of their questions
  answered in the node prompt. Each node states where human input enters,
  records assumptions in its artifact, and routes blocking choices into typed
  Plan-review decisions written in the project's `language.ui`; the strict
  PlanReviewV1 shape is spelled out in the prompt because no vendored skill
  knows that contract. Deliberate trade-off: `HANDOFF_BRANCH_NAME` is defined
  as "the branch this worktree has checked out", so the skill's branch-drift
  check compares the branch with itself — `FlowContext` exposes no branch
  name and `env` is reference-only, so there is no literal to pass; the real
  guarantee is that MAIster owns the worktree and no node switches branches.
  Side effect accepted: `HANDOFF_BRANCH_PREPARED=1` force-disables
  `workflow.plan_id_format: sequential` for run-produced plans (the skill
  logs an INFO), because the branch-named file is what discovery needs.
- **D2 — The owner's phrasings become the prompts.** The `/aif-improve` SDD
  bar, the TDD contract and the review dimension list are placed verbatim (as
  prose) on `improve` / `plan`, `implement` and both review judges. Review
  scope is the whole branch over `git.base_branch`, committed plus working
  tree.
- **D3 — Intent restatement is a prompt rule, not a node.** Upstream 2.17.0
  already preserves `## Original Request` verbatim; the plan prompt adds an
  English `## Requirements Brief`. No extra node, no extra HITL.
- **D4 — No `aif-ru` package.** All 2.19.0 skills honor
  `language.ui` / `language.artifacts` from `.ai-factory/config.yaml`; a
  project sets both to `ru` and gets Russian plans, decisions and reports.
  The flow prompts stay English (they address the agent, not the human).
- **D5 — Review by two different agents; consensus planning in `aif-dev`.**
  The owner's principle is that a review must be produced by a different
  agent/model than the one that implemented, otherwise findings do not get
  generated. So the codex `cross_review` follows the claude `code_review` in
  `aif-dev`, `aif-autonomous` and `aif-bugfix` (all three now need `claude`
  and `codex` host runners); `aif-dev-light` stays single-agent as the cheap
  path. Consensus planning stays in `aif-dev` only; the node runs once
  (rework from plan review re-enters `plan`), `plan` consumes
  `consensus_plan` by inline injection and materializes it through
  `/aif-plan full`, so the typed Plan-review pair is produced by `improve`
  exactly as before.
- **D6 — Cross-review findings are verified, not applied.** `cross_review`
  emits the skill's `review_comments` prefixed with `[cross-review]` into the
  shared `review_comments` var; the `fix` prompt verifies each marked finding
  against the code, fixes the confirmed ones and states refuting evidence for
  the rest — the owner's observed practice with codex reviews. A separate
  `cross_review_comments` var was rejected by review: the engine injects the
  judge's output var named exactly like the rework `commentsVar`
  (`vars[commentsVar] ?? vars.comments`), so a differently named var would
  arrive empty. A human rework resets both loop counters.
- **D7 — Runner intent only, three slots.** Profiles are `capability_agent`
  + `effort`; the model/adapter pins are gone (the previous
  `claude-opus-4-8` pin never matched the host and only produced resolution
  warnings). `planner` is a separate claude slot so a project can bind its
  strongest model (a fable-class runner) to planning, consensus drafting and
  synthesis while `primary` implements; `independent` is codex.
- **D6a — Verification is a routing node.** `/aif-verify` reports a gate
  result the engine never read; `checks` now emits `status: pass|warn|fail`
  as its `output.result` and `fail` reworks to `fix` with the blockers
  (Codex round-2 finding). Because `maxLoops` counts visits and every fix
  cycle re-visits `checks` and `code_review`, each judge rework declares
  `resetTargets` for the nodes it re-drives; otherwise a second judge's
  rework would trip the first judge's visit cap (CONFIG backstop) before the
  human node is reached. The price is a larger theoretical worst case (each
  cross-review round re-opens the judge's budget, each judge round re-opens
  the verify budget: ~3 × (5 + 6 × 2) fix cycles in `aif-dev` before every
  exhaustion path has fired); real loops converge in one or two rounds, and
  the platform's unattended liveness defaults still bound each session.
- **D7a — One ACP session per phase.** Planning (`planning`),
  implementation, verification (+ judge), cross-review, fix and commit never
  share a session, in every delivery flow including `aif-bugfix`.
- **D8 — Engine floors: 3.8.0 on `aif-dev`, 3.7.0 on the other delivery
  flows; `reentry: checks`.** `aif-dev` depends on the consensus prompt being
  rendered for the drafters, which only the 3.8.0 engine guarantees (D10);
  a 3.7.0 floor would admit an engine that forwards the literal template.
  Meta flows keep `2.0.0`. Hooks/limits are not declared: the platform
  applies its unattended liveness defaults.
- **D9 — Vendor from the upstream git tag, re-apply two patches.** The git
  tag carries the skill `tests/` the npm tarball omits. Patches kept: the
  `maister:output` routing block in `aif-review` (required by the judge
  nodes) and `model: opus` for Explore subagents in `aif-plan` / `aif-fix`
  (a deliberate local edit; upstream still says `sonnet`).
- **D10 — Engine gap fixed in MAIster, versioned as 3.8.0.** A consensus
  node's `prompt` reached draft participants unrendered (`{{ task.prompt }}`
  as literal text) while verifier and synthesizer prompts were rendered.
  MAIster now renders the draft prompt against the run context before
  launching drafts (strict: unknown variable → `CONFIG`, no draft created),
  scans consensus prompts for `{{ artifacts.<id>.content }}` like any other
  prompt, and bumps `MAISTER_ENGINE_VERSION` to `3.8.0` so a package can
  require the behavior. Without it, D5 cannot work. pstack's consensus
  prompts already use `{{ task.prompt }}` at `engine_min: 3.7.0`; they work
  on 3.8.0 and should raise their floor in their next release.

## Verification done

- `validate:package-compatibility --mode ci` against the branch head (tag
  label `aif/v3.0.0`): all nine flows compile against engine 3.8.0.
- MAIster: RED → GREEN unit tests for the consensus prompt rendering, the
  round-2 critique staying literal, the guarded default form, and drafts /
  agreed material reaching verifier and synthesizer as template values;
  typecheck, scoped lint, grammar/assistant tests, `validate:docs`, the
  `run_results` engine-version integration test.
- Three reviews of the branch by different agents: `aif-verify`
  (fresh-context Claude), `aif-review` (Claude on opus), Codex adversarial
  review; every confirmed finding is fixed in the branch (cross-review
  comment routing, engine floor 3.8.0, Handoff mode for plan discovery,
  pre-answered skill questions, verifier/synthesizer re-render hazard).

## Not verified yet

- A live `aif-dev` run (real claude + codex sessions) through
  `plan_consensus` → `plan` → `improve` → `plan_review`: that the synthesized
  plan lands as a proper `.ai-factory/plans/<stem>.md` and that the
  PlanReviewV1 decisions read well. Needs web + supervisor up, the package
  installed from the local checkout, and API keys for both providers.
- Known limitation: `fix` cannot declare `impl-diff` too (one producer per
  artifact id), so the `review` gate's `impl-diff` evidence keeps the
  pre-fix head; the workbench diff is live. Pre-existing since v2.x.

## Resolved with the owner (2026-09-14)

- Keep `model: opus` for the Explore subagents; planning may run on a
  fable-class model — hence the `planner` slot.
- `aif-bugfix` and `aif-autonomous` get the codex cross-review; planning,
  implementation and verification always run in different sessions.
- Consensus planning stays `aif-dev`-only for now (cost); revisit for
  `aif-autonomous` after a live run.
