# BMAD Test Architect package reference

The package tracks BMAD TEA `v4.3.1` and vendors eight workflow skills, the Murat skill and the shared knowledge module. Murat
is indexed as `bmad-tea:murat-test-architect`. Runtime support installs the
customization resolver and initializes `[modules.tea]` in `_bmad/config.toml` without overwriting
project-provided configuration.

| Flow | Output | Human decisions |
| --- | --- | --- |
| `tea-test-design` | Risk-based test design and coverage plan. | approve / rework / waive |
| `tea-automate` | Test implementation diff and verification evidence. | approve / rework / takeover |
| `tea-nfr` | NFR evidence assessment. | approve / rework / accept_risk |
| `tea-trace` | Requirements traceability and quality gate. | approve / rework / waive |
| `tea-test-review` | Test quality score and findings. | approve / rework / accept_risk |

All five flows require MAIster engine 3.7 and export a small deterministic result
spine with an open JSON payload. This makes their reports collectable by parent
orchestrators without freezing TEA's evolving domain data into a rigid schema.

For an existing 1.x installation, migrate the values from `_bmad/tea/config.yaml` to the central `[modules.tea]` table before launch. Use upstream `bmad migrate tea` for legacy customizations. The package keeps the broker MCP disabled by default.
