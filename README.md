# maister-plugins

Package monorepo for [MAIster](https://github.com/maister-dev/maister):
each package is a self-contained distribution unit carrying everything its
flows or agents need to function — flow graphs, skills, agents, and MCP server
templates.

## Layout

```
packages/
  <name>/
    maister-package.yaml     # package manifest (flows, capability bundles, mcps)
    flows/<flow-id>/flow.yaml
    capability/…             # skills/ + agents/ bundles
    maister-agents/…         # optional platform-agent definitions
    README.md                # provenance + package-specific notes
```

| Package | Contents |
| ------- | -------- |
| [`aif`](packages/aif/) | AI Factory 2.23.0 workflows: 9 flows (`aif-dev` with claude + codex consensus planning and adversarial cross-review, `aif-dev-light`, `aif-autonomous`, `aif-bugfix`, `aif-evolve`, `aif-roadmap`, `aif-init`, `aif-loop`, `aif-qa`) + vendored skills/agents bundle. |
| [`pstack`](packages/pstack/) | [pstack](https://github.com/cursor/plugins/tree/main/pstack) evidence-first engineering: 8 MAIster-native flows, full vendored skills/agents bundle, typed result profiles, and the `pstack-rigor` Evaluation Method. |
| [`superpowers`](packages/superpowers/) | Superpowers v7.0.2: 5 governed flows + all 15 upstream skills, with structured design, verification, and review handoffs. |
| [`openspec`](packages/openspec/) | OpenSpec v2.1.1: 4 spec-driven flows + all 12 upstream Agent Skills, exact-version CLI precondition, and typed change/review handoffs. |
| [`bmad-bmm`](packages/bmad-bmm/) | BMAD Method v6.12.4: planning, canonical Build, two compatibility flows, 45 upstream skills, runtime support, and 5 platform agents. |
| [`bmad-tea`](packages/bmad-tea/) | BMAD Test Architect v4.3.1: 5 typed quality flows, 8 workflows plus the Murat and module skills, and Murat as a platform agent. |
| [`bmad-cis`](packages/bmad-cis/) | BMAD CIS v0.3.2: a governed RAH discovery flow, 4 upstream workflow skills, and 6 creative platform agents. |
| [`rah`](packages/rah/) | Native evidence research: bounded depth-1/depth-2 coordinator Flows, read-only researchers and a single-role control, with explicit source/confirmation limits and EN/RU installation guidance. |
| [`core`](packages/core/) | First-party platform agents for GitHub issue intake (gh or MCP), task triage, Project Brain improvement, and experiment evaluation, plus shared MAIster skills. |
| [`core-java`](packages/core-java/) | Java and JVM skills for builds, architecture, integration testing, performance analysis, and production diagnostics. |
| [`core-react`](packages/core-react/) | React and TypeScript frontend skills for components, state and data flow, accessibility, testing, and performance. |
| [`core-pg`](packages/core-pg/) | PostgreSQL skills for schema design, migrations, query tuning, indexing, transactions, reliability, and operations. |
| [`core-skill-authoring`](packages/core-skill-authoring/) | Skill-authoring skills for designing, structuring, validating, testing, and maintaining reusable MAIster agent skills. |
| [`env-e2e`](packages/env-e2e/) | Four flows for ephemeral Compose environments and CI evidence: local verification, CI, push, or PR delivery. |
| [`spec-kit`](packages/spec-kit/) | GitHub Spec Kit 1.4.3: initialize the Claude or Codex integration, then drive specification, clarification, planning, and implementation. |
| [`stand-operations`](packages/stand-operations/) | Diagnose a configured stand component, obtain human approval for the restart, and verify the outcome independently. |

## Documentation

Per-package reference docs and design specs live under [`docs/`](docs/):

- [`docs/aif/`](docs/aif/) — AIF package reference.
- [`docs/pstack/`](docs/pstack/) — pstack-to-MAIster architecture mapping and
  extension boundary.
- [`docs/superpowers/`](docs/superpowers/) — Superpowers package reference +
  the design spec (`specs/`).
- [`docs/openspec/`](docs/openspec/) — OpenSpec package reference + the design
  spec (`specs/`).
- [`docs/bmad-bmm/`](docs/bmad-bmm/) — BMAD Method package reference.
- [`docs/bmad-tea/`](docs/bmad-tea/) — BMAD Test Architect package reference.
- [`docs/bmad-cis/`](docs/bmad-cis/) — BMAD Creative Intelligence Suite package
  reference.

## Versioning

Per-package git tags: **`<name>/vX.Y.Z`** (e.g. `aif/v3.1.0`). The tag is the
user-facing pin; MAIster resolves it to a commit SHA at install time and the
SHA is runtime truth (content-addressed cache, immutable revisions). A
package release tags only its own name — packages version independently.

## Consuming from MAIster

- **Target shape** (MAIster package management, P1+): one `packages[]` entry
  in the project's `maister.yaml` —
  `{ id: aif, source: <this repo URL>, version: aif/v3.1.0, path: packages/aif }` —
  or, with the platform catalog (P2), add this repo as a package source in
  `/settings` and install/attach from the UI.
- **Until then**: per-flow wiring — nine `flows[]` entries pointing at
  `file:///…/maister-plugins/packages/aif/flows/<id>` plus one
  `capability_imports[]` entry for `packages/aif/capability`, all
  `version: local-dev`.

Design reference: `docs/pv/package-management.md` in the MAIster repo.

## Contributing changes

Two channels:

1. **Repo-as-project**: register this repo as a normal MAIster project and
   ship package changes through tasks → runs → promotion (`pull_request`).
2. **Studio propose-upstream** (planned): fork an installed package in
   MAIster Flow Studio, edit, and propose the change as a PR from the UI.

Local iteration without publishing: point a MAIster project at a local
checkout (`file://` source / local package version) and run flows against it.

## Releasing a package

Create package tags through the release wrapper so the compatibility gate runs
against the exact clean checkout before a tag exists:

```sh
MAISTER_REPO=/path/to/mAIster ./scripts/release-package.sh aif v3.0.0
```

The compatibility command validates the package manifest, graph-only `nodes[]`
manifests and engine range. For `rah`, the wrapper also runs a real Postgres
install/trust/enable qualification against the clean candidate bytes, including
package-root schema materialization. These checks do not establish live ACP or
stand-pilot readiness. Engine compatibility audits must consume each tagged
revision's own bytes; passing a different tag label over the working tree does
not validate that historical release.
