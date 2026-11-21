# OpenSpec 2.1 reference bundle

The package materializes all current upstream Agent Skills from
`capability/skills/`. This `reference/` subtree keeps the matching schema,
templates, default config example, and license for provenance and auditability.

Contents (vendored from `@fission-ai/openspec@2.1.1`, MIT):

| Path | What it is |
| ---- | ---------- |
| `schema-spec-driven/schema.yaml` | The default OpenSpec workflow schema (artifact pipeline + dependencies). |
| `schema-spec-driven/templates/{proposal,design,tasks,spec}.md` | The artifact templates `openspec instructions <artifact>` returns. |
| `openspec-config.yaml` | The `openspec/config.yaml` written by `openspec init`. |
| `LICENSE.openspec` | Upstream MIT license. |

## Runtime model

`os-init` runs `openspec init --tools none --force`: OpenSpec owns its project
schema while MAIster owns skill materialization. Agent nodes invoke the current
skills as workflow authorities and adapt only their interactive pauses to
explicit MAIster human gates. Deterministic validation and archive commands stay
in `check`/`cli` nodes.
