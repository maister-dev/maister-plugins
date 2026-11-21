# MAIster Core React package

React and TypeScript frontend skills for MAIster agent sessions. The
package is a skill bundle: it ships no flows, platform agents, or MCP
templates.

## Intended scope

- Component and hook design.
- State management and server/client data flow.
- Accessibility and interaction quality.
- Frontend testing, rendering performance, and bundle efficiency.

## Skill sources

- [affaan-m/everything-claude-code v2.2.3](https://github.com/affaan-m/everything-claude-code/tree/v2.2.3) — `database-migrations`, `nextjs-turbopack`, `react-patterns`, `react-performance`, `react-testing`.
- [Jeffallan/claude-skills v0.4.21](https://github.com/Jeffallan/claude-skills/tree/v0.4.21) — `javascript-pro`, `nextjs-developer`, `react-expert`, `react-native-expert`, `typescript-pro`.

License notices ship in `capability/reference/`.

## Adding a skill

Create `capability/skills/<skill-id>/SKILL.md` and keep any supporting
references, scripts, examples, or templates inside that skill directory. The
`core-react-bundle` capability registers the entire `capability/` root, so no
per-skill manifest entry is required.

## Versioning

Release with a `core-react/vX.Y.Z` tag and upgrade the installed package
revision in MAIster.
