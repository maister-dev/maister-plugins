# MAIster Core package

First-party platform agents and shared skills that ship with MAIster.

## Contents

- `maister-agents/` — platform-agent definitions catalogued as
  `core:<file-stem>`.
- `capability/skills/` — shared skills materialized into supported agent
  runtimes from the installed package revision.
- `evaluation-methods/sdd-quality/` — the default MAIster Evaluation Lab method
  (M46, ADR-143): an operationalized spec-driven-development rubric with a
  strict judge result schema. Requires MAIster engine `>= 3.2.0`; older control
  planes ignore the `evaluationMethods` key. Content is inert until trusted and
  engine-compatible.
- No flows or MCP server templates. Core agents use MAIster's built-in MCP
  facade and ephemeral agent tokens. The MCP intake variant additionally
  requires a project-bound GitHub MCP.

## GitHub issue intake

Choose **one** agent per project/repository:

| Agent | GitHub access | Prerequisite |
| --- | --- | --- |
| [`core:github-intake-gh`](maister-agents/github-intake-gh.md) | Host `gh` CLI | Authenticated CLI visible inside the agent session; no GitHub MCP needed. |
| [`core:github-intake-mcp`](maister-agents/github-intake-mcp.md) | Project-bound GitHub MCP | Trusted `github-intake` MCP binding with issue read/comment tools. |

Both use the packaged [github-issue-intake skill](capability/skills/github-issue-intake/SKILL.md)
for duplicate checks, recovery, and handoff to `core:triager`. The shared skill
is materialized from `core-bundle`; the definitions supply transport-specific
operations. Both use the built-in MAIster MCP for tasks.

After upgrading core, attach the chosen agent in Project Settings → Agents,
and set `github_repository` (`OWNER/REPO`, github.com).
`batch_size` defaults to 20; empty `import_created_since` includes existing open
issues. The destination slug comes from the launch context.

For the CLI variant, the session checks
`gh auth status --active --hostname github.com` and reads the authenticated user. Existing host authentication can
be reused if visible to that execution session; successful web-side cloning
alone does not prove that. Allow the runner's shell/network operations and
provide issue read/write access without putting a token in agent config.
See the [gh API manual](https://cli.github.com/manual/gh_api).

For the MCP variant, bind `github-intake` to a trusted GitHub MCP exposing
`get_me`, `list_issues`, `search_issues`, `issue_read`, and `add_issue_comment`.
Scope credentials to the repository with Issues read/write permission and keep
secrets in host environment references. Neither variant silently switches to
the other transport on failure.

Both declare `workspace: worktree`: `none`/`repo_read` sessions deny shell
execution and can reject external MCP write permissions. Worktree allocation
and ordinary launch preconditions therefore apply, even though the agents must
leave source files and Git state unchanged.

Enable `core:triager` on `task.created` and `task.triage_requeued`, with
`auto_enqueue: off` for planning-only intake and suitable project Flows enabled.
The attach recommendation is hourly (`0 * * * *`, UTC); edit the binding to
choose its timezone and runner. Start manually with `autoApply: off`; after
checking effects, `permissions` permits unattended ACP tool approvals. The
platform scheduler must be ticking.

Keep only one variant and one cron binding enabled; avoid overlapping manual
runs. Before switching variants, disable the old one and reconcile its pending
receipts. Both variants use the same GitHub comment journal and task provenance;
private memory is not required. A new import posts one pending comment and one
completion comment; a duplicate posts only its completion comment. A prior
pending marker without a matching task is held for operator review, including
on a closed source. Verify the prior run before manually removing an orphan
pending comment to re-arm intake. A different GitHub account requires review of
prior receipts. Task provenance and verified GitHub comments reduce repeats,
but do not add transactional external-ID uniqueness to MAIster. Ambiguous
writes are held for operator review. Before enabling cron, check a new issue,
a duplicate, a repeated run, and recovery between task creation and its receipt.

## Adding a skill

Create `capability/skills/<skill-id>/SKILL.md`. References, scripts, examples,
and templates may live beside `SKILL.md` inside the same skill directory.
Individual skills are discovered from the registered `core-bundle` capability;
they are not listed separately in `maister-package.yaml`.

## Versioning

Release with a `core/vX.Y.Z` tag. Existing MAIster installations must upgrade
to that package revision before the new content is available to runs.


### Operational intake compatibility

The GitHub gh and MCP variants require engine **3.10.0 or later** and declare
`kind: operational` / `completion.contract: operational_v1`. Source access,
execution mode, tool approval, and completion are separate settings. Both retain
normal permission decisions and their transport requirements. A complete scan
with no new work finishes Done. Partial import, authorization failure, missing
or malformed result, and unexpected source changes finish with actionable
failure diagnostics; the platform preserves history/evidence and disposes the
execution workspace without review or publication.

Release the platform, its additive migrations and compatible workers first.
Keep existing core pins until platform acceptance passes. Then qualify the exact
core revision (`core/v1.4.0`) with the platform compatibility
CLI and both transport fixtures before releasing it or changing attachment pins.
Old engines must refuse this package; do not remove the floor to install it.
Rollback requires draining operational runs and compatible cleanup/evidence
owners; downgrading running workers alone is unsafe.


### Operational triager

Triager also declares `kind: operational` and `operational_v1`. One task is one
work item. Confirmed holds, duplicates and already-flagged no-ops are successful
operations; incomplete mutations or runner/API failures are operational failures.
Human asks use `reTriggerMode: agent`: the answer resumes the same run. Explicit
human triage requeue remains available. The kind does not enable automatic tool
approval, change the delivery Flow runner or publish source changes. New package
pins apply only to new launches; existing runs retain their frozen contracts.


### Incoming qualification

Core `core/v1.4.0` requires engine 3.10.0 and explicit project qualification policy
`required` before attach/enable/launch. Both importers declare the intake role and
capture original source requests in Incoming. Triager declares the qualifier role,
`repo_read` / `workspace_ref: task_target`, and inspects the frozen detached SHA with
native read-only tools. It uses the shared task-qualification skill for all seven
checks. It cannot run shell commands, edit source or bypass approvals. Missing
runtime bug evidence stays needs_review; code inspection is not reproduction.

Ready, needs_information, needs_review and not_actionable are assessment decisions,
separate from operational outcomes. A held request may be successfully assessed.
Candidates publish only on clean validated completion and never on partial failure.
Local Human asks resume the same run. Current task/target revisions and delivery
admission remain authoritative across edits, requeue, package upgrades and retries.
Release platform/schema/MCP first, then core `core/v1.4.0`, then explicitly
set project policy and upgrade attachment pins. No live credentials or provider
configuration is shipped with the package.
