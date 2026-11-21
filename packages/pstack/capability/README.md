# Vendored pstack capability

This directory contains the pstack skills and reusable agent definitions from
`cursor/plugins`, pinned to commit
`792440e8a560a4a3f63748cdee70491ecd412982` (pstack `0.15.46`). The upstream
license is preserved in `LICENSE.pstack`.

The package preserves the upstream skill and agent identifiers.

Some skills describe Cursor-native controls such as Task subagents,
`AskQuestion`, `/loop`, pstack model-selection rules, worktrees, or PR
operations. Those descriptions remain useful as source guidance, but they are
not the MAIster runtime contract. The package flows prepend an explicit
execution contract: MAIster owns orchestration, workspace lifecycle, review,
promotion, and human gates; capability agents stay inside the current node and
do not depend on Cursor-native controls.
