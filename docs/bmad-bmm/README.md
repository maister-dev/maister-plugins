# BMAD Method BMM package reference

The package tracks BMAD Method `v6.12.4`. It vendors 45 upstream skills from
core, BMM plan/ship, and v6 compatibility shims. Five current personas—Mary,
John, Sally, Winston, and Amelia—are MAIster platform agents in
`maister-agents/`; retired Paige is not carried forward.

| Flow | Purpose | Status |
| --- | --- | --- |
| `bmm-plan` | Brief → PRD → UX → architecture spine → epics/stories → sprint planning/readiness. | Current; typed public result and final approve/rework/defer gate. |
| `bmm-build` | Current Phase 4 Build → independent review → approve/rework/takeover. | Preferred implementation flow. |
| `bmm-dev-story` | Former create-story/dev-story cycle. | Compatibility flow backed by upstream shims. |
| `bmm-quick-dev` | Existing small-change entry point. | Compatibility id routed to current `bmad-build`. |

BMAD 6.11 renamed Quick Dev to Build, consolidated architecture/readiness
behavior, and renders Build into immutable content-addressed snapshots. The
package's internal `bmad-runtime-support` skill installs version-matched scripts
under `_bmad/scripts/`, creates central `_bmad/config.toml`, and preserves the
legacy module YAML needed by retained shims. Every BMM flow refuses launch when
`uv` is absent; the upstream scripts require Python 3.11+.

Planning and implementation remain normal MAIster writer flows. `bmm-plan` and
`bmm-build` publish typed results so a parent RAH can collect them after their
human governance and promotion lifecycle completes. Within `bmm-build`, the
writer publishes structured spec, change, commit, and verification pointers;
the independent reviewer treats them as evidence hints and confirms them
against the worktree rather than rediscovering the implementation context.
