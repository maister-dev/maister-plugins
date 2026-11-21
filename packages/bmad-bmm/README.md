# BMAD Method BMM package

MAIster packaging of [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD)
`v6.12.4` at commit `bab9082c3e884e0d72c759bcd1a6d90bcc01be84`.

It contains 45 upstream core/BMM/shim skills, one internal runtime-support
skill, five platform agents under `maister-agents/`, and four flows:
`bmm-plan`, canonical `bmm-build`, plus compatibility entry points
`bmm-dev-story` and `bmm-quick-dev`. The package requires `uv` with Python
3.11+ because current Build renders content-addressed workflow snapshots.
`bmm-build` passes spec, commit, changed-file, and verification pointers from
the writer to its fresh-context reviewer as a typed handoff.

See [the package reference](../../docs/bmad-bmm/README.md). Upstream content
remains under the MIT license in `capability/reference/LICENSE.bmad`.
