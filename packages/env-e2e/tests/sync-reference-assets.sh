#!/usr/bin/env bash
set -euo pipefail

flows="$(cd "$(dirname "${BASH_SOURCE[0]}")/../flows" && pwd)"
source_script="$flows/env-e2e/scripts/run-e2e.sh"

for export in env-e2e-ci env-e2e-ci-push env-e2e-ci-pr; do
  shipped="$flows/$export/scripts/run-e2e.sh"
  if [[ "${1:-}" == "--check" ]]; then
    cmp "$source_script" "$shipped"
  else
    cp "$source_script" "$shipped"
  fi
done
