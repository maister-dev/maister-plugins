# Env-e2e Flow package

Ephemeral, fully internal docker-compose environment + Playwright e2e as
**readiness evidence**. One `check` node owns the whole env lifecycle
atomically — up → seed → test → capture → down — with teardown guaranteed by a
shell trap on every exit path. A red suite drives a bounded fix loop; loop
exhaustion escalates to a human reviewer with the red report; **`pass` is the
only path to `done`** — the flow never auto-ships a red suite.

Normative SSOT: [design spec](../../docs/env-e2e/specs/2026-07-31-env-e2e-design.md).
This README summarizes and links the spec — it never forks it.

## Contracts (summary — spec §§2-6 are normative)

- **Exit-0 protocol.** `scripts/run-e2e.sh` exits `0` whenever the runner
  service executed (tests ran) — the verdict travels in the result JSON
  (`verdict: pass|fail`) and routes the graph via `decide`. Non-zero exit is
  reserved for `config`/`env` failure classes and fails the run (check nodes
  have no failure transition — rework cannot fix a broken env). Docker-level
  runner failures (reserved codes 125/126/127, or a trailing
  `Error response from daemon:` marker — compose flattens CLI errors to
  exit 1) are classified `env`, never a verdict.
- **Engine floor.** `compat.engine_min: 3.3.0` — the packaged script is
  executed from the installed revision via `MAISTER_FLOW_DIR` (platform
  ADR-154). On an older engine the command's
  `${MAISTER_FLOW_DIR:?…}` guard fails with an actionable one-liner.
- **Web-tier Docker.** `cli`/`check` nodes execute on the MAIster **web
  tier**: the Docker daemon + compose v2 must live there. Launch preflight
  (`requirements`) probes `docker info` and `docker compose version` before
  any worktree/session/token spend — host invariants only: the config file
  is deliberately NOT probed (probes run against the default-branch
  checkout; a branch adding it would be wrongly refused) and is validated
  in-run at the tested revision instead.
- **Timeout budget.** The e2e node declares `settings.timeoutMs: 900000`
  (15 min), clamped by the host ceiling `MAISTER_MAX_CLI_TIMEOUT_MS`
  (default 1 h). On timeout the engine SIGTERMs the whole process group; the
  trap has a 30 s grace to tear the env down.
- **Artifacts land in the run dir.** `e2e-report.tar.gz` (Playwright
  `playwright-report/` + `test-results/` + full runner log) and
  `e2e-compose-logs.txt`, re-produced on **every** attempt;
  `requiredFor: [review, merge]` currency on the report is the promotion
  gate.
- **Rework feedback.** The failing block is the `e2e_comments` field of the
  result JSON — injected into the next `implement` attempt
  (`rework.commentsVar`), bounded by `maxLoops: 3`, then `onExhaustion`
  escalation to the `review` human node (`resetTargets: [e2e]` grants a
  fresh budget per human-approved round).
- **Isolation — enforced.** Every compose invocation uses
  `-p maister-run-<runId>`; the config phase renders the resolved compose
  model and refuses (config class) published ports, `container_name:` pins,
  and `network_mode: host` — the runner reaches services by compose-network
  DNS only.
- **Sanitized env.** Every docker invocation runs under
  `env -i PATH HOME COMPOSE_PROJECT_NAME + E2E_ENV` — defense-in-depth over
  the platform's ADR-153 allow-list. `DOCKER_HOST` is deliberately not
  propagated; use a docker context (`$HOME/.docker`) for non-default sockets.

## Per-project config — `.maister-env-e2e.sh` (repo root, sourced bash)

| Variable | Required | Meaning |
| --- | --- | --- |
| `E2E_COMPOSE_FILES` | yes | Bash array of repo-relative compose files; `-f` merge order = array order. |
| `E2E_RUNNER_SERVICE` | yes | Compose service (profile `e2e`) that runs Playwright. |
| `E2E_WAIT_TIMEOUT` | no (120) | Seconds for `up --wait`. |
| `E2E_SEED_COMMAND` | no | Host `bash -c` hook after up, before tests (`$E2E_COMPOSE` prefix var available). |
| `E2E_ENV` | no | `NAME=VALUE` pairs for compose interpolation + the runner container (`-e`). |

Missing/invalid config → actionable `[env-e2e:config] …` failure before any
compose resource exists.

## Orphan sweep (crash-only cases)

Teardown is trap-guaranteed; only a SIGKILL-class death (grace exceeded,
> 4 MiB combined step output, hard web-process crash) can strand an env.
**Active runs use the same `maister-run-` prefix** — the listing commands are
discovery only; before tearing an id down, verify that run is terminal
(Crashed/Failed/Done) on the MAIster board. Never run a prefix-wide down.

```bash
docker compose ls | grep maister-run-        # discovery: stranded projects
docker ps --filter "name=maister-run-"       # discovery: stranded containers
# for a SPECIFIC id whose run is confirmed terminal in MAIster:
docker compose -p maister-run-<id> down --volumes --remove-orphans
```

## Requirements

- **Web-tier Docker socket**: `cli`/`check` nodes execute on the MAIster web
  tier — the Docker daemon + compose v2 must live on that host. The flow's
  `requirements` probes (`docker info`, `docker compose version`) refuse
  launch actionably before any worktree/session/token spend; the config file
  is validated in-run at the tested revision (not probed — probes see only
  the default branch).
- **Engine ≥ 3.3.0** (`MAISTER_FLOW_DIR`, platform ADR-154). Older engines
  fail at the command's `${MAISTER_FLOW_DIR:?…}` guard with a one-line
  remediation.
- **Timeout budget**: the node declares 900 s; the host ceiling is
  `MAISTER_MAX_CLI_TIMEOUT_MS` (default 1 h). On deployments predating the
  timeoutMs wiring the default 300 s applies — the fixture fits it; size
  your project's suite (or raise the ceiling) accordingly.
- **Image pre-pull**: run `examples/bootstrap-fixture.sh` (or pre-pull your
  stack's images) so the first run's `up --wait` fits the budget.
- **npm egress**: the runner performs `npm ci` — "fully internal" means zero
  **published ports**, not zero network egress.

## Fixture walkthrough

```bash
packages/env-e2e/examples/bootstrap-fixture.sh /path/to/fx-green
packages/env-e2e/examples/bootstrap-fixture.sh --red /path/to/fx-red
```

Each bootstrap refuses a non-empty target, copies the fixture (healthchecked
nginx `web` + postgres `db`, Playwright runner under compose profile `e2e`,
committed lockfile pinned to the runner image version, green `home.spec.ts` +
toggleable `red.spec.ts`), writes `maister.yaml` + `.maister-env-e2e.sh`
(`--red` appends `E2E_ENV=(FIXTURE_RED=1)`), git-inits, pre-pulls images, and
prints the registration steps. Green ends done-side; red exercises
fail → rework → converge/escalate. Running green + red simultaneously is the
concurrency proof (distinct `maister-run-*` compose projects).


## Remote CI reference Flows

The remote CI reference exports require MAIster 3.15 or newer. They run the Playwright
checks, require the current report, publish the tested branch and await
`build` on the exact tested commit. A failed remote check re-enters the
bounded implementation loop. Timeout and exhausted remote rework carry
classified failure into the run's completion policy.

- `env-e2e-ci` reads the GitHub Actions result through the provider scanner.
  Review the issuer and required check name before pinning this export.
- `env-e2e-ci-push` accepts the named `build` callback. Configure
  `remote_ci.on.issuer` as the ID of the trusted project token before pinning
  the Flow for autonomous completion. Give the token only `waits:signal`.
  Use the callback address for the exact ref and SHA. A failed callback can
  include `failedChecks` for rework context. Autonomous completion also
  requires a current `build` result from `provider_issuer` on the same SHA.
  Approve both source identities in the project policy.

- `env-e2e-ci-pr` opens a ready PR and waits for a confirmed merge on the
  original source SHA. At launch select Pull request delivery. A confirmed
  conflict can use the engine's branch-sync resolver once and repeat local
  verification, publication, CI and review on the new commit. The operator
  handles closed PRs or conflicts for which the current policy refuses recovery.

The completing project must enable the execution-policy axis and name the
approved CI source. At interactive launch, authorize publication separately.
The exports also work with human-controlled promotion.

A release must ship the canonical env-e2e lifecycle script within each Flow
directory. Run `tests/sync-reference-assets.sh` after editing the canonical
script. Use `tests/sync-reference-assets.sh --check` to verify the shipped
copies match before cutting a package revision.

## See also

- [Design spec (SSOT)](../../docs/env-e2e/specs/2026-07-31-env-e2e-design.md)
- [Deep reference](../../docs/env-e2e/README.md) — node walkthrough, result
  contract, failure-class table, script phase machine
- `tests/test-run-e2e.sh` — the 12-case script harness (docker required)
