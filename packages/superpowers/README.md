# Superpowers package

MAIster packaging of [obra/superpowers](https://github.com/obra/superpowers),
vendored from upstream `v7.0.2` at commit
`22f0b463e7a5e579904dd6211a520321035526f7`.

The package ships 15 upstream skills and two package agents. `sp-plan` and
`sp-dev` run an independent builder check before design approval. `sp-debug`,
`sp-dev` and `sp-execute` isolate whole-branch review from the writer and verifier.

`sp-execute-pr` executes an approved plan and uses MAIster 3.15 publication and
wait nodes to track a ready PR through CI and merge. Its launch contract and
project prerequisites are in [the flow reference](../../docs/superpowers/README.md).
The upstream MIT license is in `capability/LICENSE.superpowers`.
