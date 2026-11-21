# Superpowers package reference

The package tracks upstream Superpowers `v7.0.2` and vendors all 15 skills
verbatim. MAIster owns orchestration, worktrees, promotion, and human approval;
the skills own engineering discipline inside agent nodes.

| Flow | Purpose | Human gates |
| --- | --- | --- |
| `sp-dev` | Design, plan, implement with TDD, verify, review, finalize. | Design, plan, final implementation review. |
| `sp-debug` | Root-cause investigation, regression test, fix, verify, review. | Final implementation review. |
| `sp-plan` | Produce a design and implementation plan without coding. | Design and typed plan review, with defer available at design review. |
| `sp-execute` | Execute an already approved plan. | Final implementation review. |
| `sp-execute-pr` | Execute an approved plan inline, verify the commit, publish a ready PR, wait for CI and merge. | Launch authorization and maintainer intervention on stale, cancelled, closed or conflicted delivery. |

## Design and execution

`superpowers:builder-check` reads the committed design in its own session. Its
findings go to the design review and the planner. The typed plan review records
remaining owner choices before execution. Plans identify testable deliverables,
interfaces and Review Focus items. Inline and subagent-driven execution both
carry the progress ledger, rulings and deferred minors into final review.
A blocked execution stops at a human node for a response.

`superpowers:code-reviewer` reads the actual candidate in a separate session
from verification in the three local coding flows. Review findings travel
through structured output into rework and the final result.

## PR delivery

`sp-execute-pr` requires engine 3.15.0, a task naming an approved plan, a tracked
executable `scripts/verify`, and an authorized project Git origin. Configure
the GitHub CI issuer `github-actions` and exact required check `build` before
launch. Authorize branch publication and PR creation for the selected revision.
MAIster runs local verification, publishes the candidate, waits up to one hour
for its check, and runs a blocking whole-branch judgment before waiting up to
24 hours for the provider to report a merge. A failed check can return to the
writer twice. Project policy and launch authorization govern automatic settlement.
The Flow observes the PR merge and leaves the merge decision to the repository.
