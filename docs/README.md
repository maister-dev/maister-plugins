# maister-plugins docs

Reference documentation for the MAIster flow packages in this repo. Each
package is a self-contained distribution unit (flow graphs + capability bundle
+ manifest) consumed by [MAIster](https://github.com/maister-dev/maister)
through `maister.yaml packages[]`, pinned by a per-package git tag
(`<name>/vX.Y.Z`).

## Packages

| Package | Reference | Flows | Capability bundle |
| ------- | --------- | ----- | ----------------- |
| `aif` | [aif/](aif/README.md) | `aif-dev` (consensus planning + codex cross-review), `aif-dev-light`, `aif-autonomous`, `aif-bugfix`, `aif-evolve`, `aif-roadmap`, `aif-init`, `aif-loop`, `aif-qa` | AI Factory skills + subagents (`github.com/lee-to/ai-factory@2.19.0`) |
| `pstack` | [pstack/](pstack/README.md) | `pstack-investigate`, `pstack-interrogate`, `pstack-bugfix`, `pstack-feature`, `pstack-refactor`, `pstack-perf`, `pstack-prototype`, `pstack-visual-parity` | Full pstack `0.14.8` skills + agents (`cursor/plugins@7314f723`) |
| `superpowers` | [superpowers/](superpowers/README.md) | `sp-dev`, `sp-debug`, `sp-plan`, `sp-execute` | superpowers skills, all 14 (`github.com/obra/superpowers@5.1.0`) |
| `openspec` | [openspec/](openspec/README.md) | `os-dev`, `os-propose`, `os-apply`, `os-init` | reference-only — drives the `openspec` CLI (`@fission-ai/openspec@1.4.1`, installed by `setup.sh` / `os-init`); ADR-091 `requirements` precondition |
| `bmad-bmm` | [bmad-bmm/](bmad-bmm/README.md) | `bmm-plan`, `bmm-dev-story`, `bmm-quick-dev` | BMAD Method v6 BMM SDLC: 6 platform-agent personas + 26 vendored BMM skills (`github.com/bmad-code-org/BMAD-METHOD@v6.8.0`) |
| `bmad-tea` | [bmad-tea/](bmad-tea/README.md) | `tea-test-design`, `tea-automate`, `tea-nfr`, `tea-trace`, `tea-test-review` | BMAD Test Architect: Murat platform agent + 9 vendored testarch skills (`github.com/bmad-code-org/bmad-method-test-architecture-enterprise@v1.19.0`) |
| `bmad-cis` | [bmad-cis/](bmad-cis/README.md) | `cis-discovery` | BMAD Creative Intelligence Suite: 6 creative platform-agent personas + 4 vendored creative skills (`github.com/bmad-code-org/bmad-module-creative-intelligence-suite@v0.2.1`) |
| `env-e2e` | [env-e2e/](env-e2e/README.md) | `env-e2e` | Ephemeral compose env + Playwright e2e as readiness evidence: atomic `check`-node lifecycle script (`MAISTER_FLOW_DIR`, engine ≥ 3.3.0), verdict-routed rework loop, trap-guaranteed teardown; no capability bundle |

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
