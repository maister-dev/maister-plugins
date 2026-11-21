---
name: bmad-tea-runtime-support
description: Internal runtime support for the vendored BMAD Test Architect skills. MAIster flows call its preparation script before invoking a TEA workflow.
---

# BMAD runtime support

This is an internal package skill. Run `prepare.sh <project-slug>` from the
project root before invoking another vendored TEA skill. It installs the
version-matched customization resolver under `_bmad/scripts/` and creates the
package's default configuration only when the project has not supplied it.
