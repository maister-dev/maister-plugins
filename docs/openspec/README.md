# OpenSpec package reference

The package tracks OpenSpec `v2.1.1`, including all 12 upstream Agent Skills
and the current spec-driven schema. `setup.sh` and `os-init` install the exact
matching CLI; `os-dev`, `os-propose`, and `os-apply` fail their launch
precondition when another version is on `PATH`.

| Flow | Purpose | Key behavior |
| --- | --- | --- |
| `os-init` | Initialize a repository. | Runs `openspec init --tools none --force`, because MAIster already materializes the skills. |
| `os-propose` | Planning-only proposal. | Uses `openspec-propose`, validates strictly, exports a typed result, and supports approve/rework/defer. |
| `os-apply` | Apply an existing proposal. | Uses apply and verify skills, then review and explicit archive. |
| `os-dev` | Propose and implement end to end. | Human approval separates planning from implementation. |

Agent nodes treat current upstream skills as workflow authorities while adapting
interactive pauses to MAIster human gates. Deterministic validation and archive
remain `check`/`cli` nodes. Apply nodes publish the resolved `changeName`, so the
archive command targets that exact change instead of relying on “only one active
change” ambient state. `os-dev` also carries the proposed name directly into the
apply node, while `os-dev` and `os-apply` pass structured review findings into
the fix loop and expose the latest reviewed result to parent orchestrators.

The setup hook performs a global npm install and therefore remains subject to
MAIster's package exec-trust gate.
