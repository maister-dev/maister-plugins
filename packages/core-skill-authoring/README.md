# MAIster Core Skill Authoring package

Skills for creating and maintaining reusable skills consumed by
MAIster agent sessions. The package is skill-only: it ships no flows, platform
agents, or MCP templates.

## Intended scope

- Skill purpose, triggering conditions, and behavioral boundaries.
- `SKILL.md` structure and progressive disclosure.
- References, scripts, examples, templates, and reusable assets.
- Schema validation, trigger testing, quality review, and maintenance.
- Packaging skills for predictable use across supported agent runtimes.

## Skill sources

- [affaan-m/everything-claude-code v2.2.3](https://github.com/affaan-m/everything-claude-code/tree/v2.2.3) — `prompt-optimizer`, `skill-comply`, `skill-scout`, `skill-stocktake`.
- [Jeffallan/claude-skills v0.4.21](https://github.com/Jeffallan/claude-skills/tree/v0.4.21) — `prompt-engineer`.

License notices ship in `capability/reference/`.

## Adding a skill

Create `capability/skills/<skill-id>/SKILL.md` and keep supporting references,
scripts, examples, templates, and assets inside that skill directory. The
`core-skill-authoring-bundle` capability registers the whole `capability/`
root, so no per-skill manifest entry is required.

## Versioning

Release with a `core-skill-authoring/vX.Y.Z` tag and upgrade the installed
package revision in MAIster.
