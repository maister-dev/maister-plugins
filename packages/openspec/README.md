# OpenSpec package

MAIster packaging of [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec),
using upstream `v2.1.1` at commit
`0c737dc1b543249b38b0f4716816fcf493d894dd`.

The package ships all 12 upstream Agent Skills, the current spec-driven schema,
and four flows: `os-init`, `os-propose`, `os-apply`, and `os-dev`. The trusted
setup hook and `os-init` enforce `@fission-ai/openspec@2.1.1`; other flows
refuse launch against a different CLI version. Structured outputs carry the
approved `changeName` into apply/archive and feed independent review findings
into rework; proposal and implementation flows expose typed public results.

The npm distribution requires Node.js 22.20.0 or later. A CLI node verifies the resolved planning root in the run worktree before an agent edits artifacts; standalone stores are outside their promotion workspace.

See [the package reference](../../docs/openspec/README.md). Vendored upstream
content remains under the MIT license in
`capability/reference/LICENSE.openspec`.
