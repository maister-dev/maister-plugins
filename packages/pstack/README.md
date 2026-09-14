# pstack Flow package

The [pstack](https://github.com/cursor/plugins/tree/main/pstack) engineering
methodology packaged for MAIster. It combines the upstream skills and reusable
agents with eight MAIster-native Flow graphs, structured result contracts, and
the `pstack-rigor` Evaluation Method.

The package is self-contained and has no package or MCP dependencies. It is
versioned independently with `pstack/vX.Y.Z` tags.

## Provenance

- Upstream: `cursor/plugins`, pstack `0.14.8`, commit
  `7314f723a487ec406b6369fe5865ba034cfed166`.
- License: MIT, preserved at `capability/LICENSE.pstack`.
- Vendored content: all upstream `skills/` and `agents/` files.
- Adaptations: only the `poteto-mode`, `make-bot-ui`, and `comment-sicko`
  identifiers were normalized for portable skill loaders.

## What changed in `pstack/v1.1.0`

`pstack-feature`, `pstack-investigate` and `pstack-prototype` require MAIster
engine `>= 3.8.0`: their `consensus` nodes interpolate `{{ task.prompt }}`
into the draft prompt, and only the 3.8.0 engine renders a consensus prompt
for the draft participants — on earlier engines they received the template
text literally. The other five flows stay at `3.7.0`. No skill, agent or
graph change otherwise.

## Flows

| Flow                   | Purpose                                                                | Human gate                     |
| ---------------------- | ---------------------------------------------------------------------- | ------------------------------ |
| `pstack-investigate`   | Read-only multi-model investigation with evidence/inference separation | Only when consensus fails      |
| `pstack-interrogate`   | Repository-grounded questions and explicit decisions                   | Answers/default acceptance     |
| `pstack-bugfix`        | Reproduce, diagnose, root-cause fix, independent verification          | Final approval or blocked loop |
| `pstack-feature`       | Shape-first consensus design and end-to-end delivery                   | Final approval or blocked loop |
| `pstack-refactor`      | Freeze observable behavior, restructure, prove equivalence             | Final approval or blocked loop |
| `pstack-perf`          | Reproducible baseline, causal optimization, before/after measurement   | Final approval or blocked loop |
| `pstack-prototype`     | Disposable artifact-scoped experiment for a named decision             | Accept evidence or rework      |
| `pstack-visual-parity` | Reference capture, implementation, repeated visual comparison          | Final visual approval          |

`pstack-investigate`, `pstack-interrogate`, and `pstack-prototype` publish typed
public results and can complete without source promotion. Code-changing flows
produce current diff and verification artifacts, use bounded rework, and only
commit after human approval.

## Runtime contract

Upstream pstack assumes Cursor controls such as Task subagents,
`AskQuestion`, `/loop`, configurable model rules, and playbooks that may own
worktrees or pull requests. The MAIster flows intentionally replace those
controls:

- Flow nodes, `consensus`, `judge`, and rework edges own orchestration.
- MAIster `human` nodes own questions and approval.
- The supervisor owns sessions; MAIster owns worktrees and promotion.
- Flow prompts forbid branch switching, worktree creation, push, merge, and PR
  side effects.
- Claude and Codex are portable runner slots, not fixed model IDs. Project
  bindings select the actual configured runtimes.
- Evidence moves between fresh phases as typed artifacts and structured
  results, rather than depending on hidden chat or subagent state.

The full vendored skill set remains available for direct agent use. Directly
invoking `poteto-mode` still exposes Cursor-native instructions; the eight
packaged flows are the supported portable execution surface.

## Evaluation and result contracts

`pstack-rigor` is a three-judge, disagreement-aware rubric over five axes:
problem understanding, evidence quality, change discipline, demonstrated
correctness, and decision-useful communication. Missing evidence is explicitly
insufficient rather than silently scored as failure or success.

Package-level `result_profiles` expose reusable contracts for delegated agents:
`investigation`, `candidate`, `review`, and `verification`. Each keeps a small
deterministic routing spine and open JSON payload fields for domain-specific
evidence.

## Install

```yaml
packages:
  - id: pstack
    source: github.com/<org>/maister-plugins
    version: pstack/v1.1.0
    path: packages/pstack
```

All flows require MAIster engine `>= 3.7.0` for portable runner profiles,
consensus, typed results, and package-level result profiles; the three
consensus flows (`pstack-feature`, `pstack-investigate`, `pstack-prototype`)
require `>= 3.8.0` for the rendered consensus prompt. `setup.sh` is an inert
no-op because capability materialization supplies the skills and agents.

The architecture mapping and extension boundary are documented in
[`../../docs/pstack/README.md`](../../docs/pstack/README.md).
