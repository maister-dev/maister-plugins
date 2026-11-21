# MAIster Core PostgreSQL package

PostgreSQL engineering skills for MAIster agent sessions. The
package is a skill bundle: it ships no flows, platform agents, or MCP
templates.

## Intended scope

- Schema design and safe migrations.
- Query planning, indexing, and performance tuning.
- Transactions, concurrency, and data integrity.
- Reliability, maintenance, observability, and production operations.

## Skill sources

- [affaan-m/everything-claude-code v2.2.3](https://github.com/affaan-m/everything-claude-code/tree/v2.2.3) — `database-migrations`, `postgres-patterns`.
- [Jeffallan/claude-skills v0.4.21](https://github.com/Jeffallan/claude-skills/tree/v0.4.21) — `database-optimizer`, `postgres-pro`, `sql-pro`.

License notices ship in `capability/reference/`.

## Adding a skill

Create `capability/skills/<skill-id>/SKILL.md` and keep any supporting
references, scripts, examples, or templates inside that skill directory. The
`core-pg-bundle` capability registers the entire `capability/` root, so no
per-skill manifest entry is required.

## Versioning

Release with a `core-pg/vX.Y.Z` tag and upgrade the installed package revision
in MAIster.
