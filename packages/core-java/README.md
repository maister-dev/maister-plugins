# MAIster Core Java package

Java engineering skills for MAIster agent sessions. The package is
a skill bundle: it ships no flows, platform agents, or MCP templates.

## Intended scope

- JVM build systems and dependency management.
- Java application architecture and maintainability.
- Integration and end-to-end testing.
- Performance analysis and production diagnostics.

## Skill sources

- [affaan-m/everything-claude-code v2.2.3](https://github.com/affaan-m/everything-claude-code/tree/v2.2.3) — `java-coding-standards`, `jpa-patterns`, `kotlin-coroutines-flows`, `kotlin-exposed-patterns`, `kotlin-ktor-patterns`, `kotlin-patterns`, `kotlin-testing`, `quarkus-patterns`, `quarkus-security`, `quarkus-tdd`, `quarkus-verification`, `springboot-patterns`, `springboot-security`, `springboot-tdd`, `springboot-verification`.
- [Jeffallan/claude-skills v0.4.21](https://github.com/Jeffallan/claude-skills/tree/v0.4.21) — `java-architect`, `kotlin-specialist`, `spring-boot-engineer`.

License notices ship in `capability/reference/`.

## Adding a skill

Create `capability/skills/<skill-id>/SKILL.md` and keep any supporting
references, scripts, examples, or templates inside that skill directory. The
`core-java-bundle` capability registers the entire `capability/` root, so no
per-skill manifest entry is required.

## Versioning

Release with a `core-java/vX.Y.Z` tag and upgrade the installed package revision
in MAIster.
