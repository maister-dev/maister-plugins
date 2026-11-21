# maister-plugins docs

Reference documentation for the MAIster flow packages in this repo. Each
package is a self-contained distribution unit (flow graphs + capability bundle
+ manifest) consumed by [MAIster](https://github.com/maister-dev/maister)
through `maister.yaml packages[]`, pinned by a per-package git tag
(`<name>/vX.Y.Z`).

## Packages

| Package | Exported Flows | Reference |
| --- | --- | --- |
| `aif` | `aif-dev`, `aif-dev-light`, `aif-autonomous`, `aif-bugfix`, `aif-evolve`, `aif-roadmap`, `aif-init`, `aif-loop`, `aif-qa` | [Package reference](aif/README.md) |
| `bmad-bmm` | `bmm-plan`, `bmm-build`, `bmm-dev-story`, `bmm-quick-dev` | [Package reference](bmad-bmm/README.md) |
| `bmad-cis` | `cis-discovery` | [Package reference](bmad-cis/README.md) |
| `bmad-tea` | `tea-test-design`, `tea-automate`, `tea-nfr`, `tea-trace`, `tea-test-review` | [Package reference](bmad-tea/README.md) |
| `core` | — | [Package reference](../packages/core/README.md) |
| `core-java` | — | [Package reference](../packages/core-java/README.md) |
| `core-pg` | — | [Package reference](../packages/core-pg/README.md) |
| `core-react` | — | [Package reference](../packages/core-react/README.md) |
| `core-skill-authoring` | — | [Package reference](../packages/core-skill-authoring/README.md) |
| `env-e2e` | `env-e2e`, `env-e2e-ci`, `env-e2e-ci-push`, `env-e2e-ci-pr` | [Package reference](env-e2e/README.md) |
| `openspec` | `os-dev`, `os-propose`, `os-apply`, `os-init` | [Package reference](openspec/README.md) |
| `pstack` | `pstack-investigate`, `pstack-bugfix`, `pstack-feature`, `pstack-interrogate`, `pstack-refactor`, `pstack-perf`, `pstack-prototype`, `pstack-visual-parity` | [Package reference](pstack/README.md) |
| `rah` | `rah-root-d1`, `rah-root-d2`, `rah-research`, `rah-control` | [Package reference](../packages/rah/README.md) |
| `spec-kit` | `sk-dev`, `sk-init`, `sk-dev-codex`, `sk-init-codex` | [Package reference](../packages/spec-kit/README.md) |
| `stand-operations` | `stand-maintenance` | [Package reference](../packages/stand-operations/README.md) |
| `superpowers` | `sp-dev`, `sp-debug`, `sp-plan`, `sp-execute`, `sp-execute-pr` | [Package reference](superpowers/README.md) |

## What every package documents

- **Flows** — the typed-node graphs (`flow.yaml`): nodes, transitions, gates,
  HITL placement, rework loops.
- **Capability bundle** — the vendored skills/agents materialised into each
  session worktree's `.claude/` at launch.
- **Reconciliation** — how the upstream framework's interactivity and git
  ownership are mapped onto MAIster-native HITL + worktree/promotion ownership
  (the framework must not create branches, merge, push, or ask the user
  directly).
- **Policies** — runner profile, `compat.engine_min`, `session_policy`,
  `retry_policy`, `verdict_calibration`, rework `workspacePolicies`.

## How MAIster materialises a capability bundle (claude adapter)

Verified against MAIster `web/lib/capabilities/*` + the
`@agentclientprotocol/claude-agent-acp@0.37.0` adapter:

- **Skills + agents files are copied wholesale** at launch:
  `capability/skills/*` → `<worktree>/.claude/skills/*` and
  `capability/agents/*` → `<worktree>/.claude/agents/*` (per-project, for every
  Installed bundle — **not** gated on a node's `settings.skills`).
- The adapter sets `settingSources: ["user","project","local"]`, so the SDK
  loads those project `.claude/` skills + agents; the `claude_code` system
  preset exposes the Skill + Task (subagent) tools. `AskUserQuestion` is the
  only force-disabled tool.
- **`rule`-kind capabilities are NOT delivered** to a claude session today (no
  `CLAUDE.md`/`AGENTS.md`/context write) — packages that need always-on
  guidance must inline it into node prompts, not ship it as a rule.
- Per-node `settings` deliver `tools`→`permissions.allow`,
  `permissionMode`→`permissions.defaultMode`, and `mcps`→ACP `mcpServers` via
  `<worktree>/.claude/settings.local.json`. Capability *enforcement* (skills /
  restrictions / workspaceAccess) stays advisory (`instructed`) this milestone.

See each package's reference page for how it uses these facts.
