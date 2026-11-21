#!/usr/bin/env bash
set -euo pipefail

# Package setup is exec-trust-gated and intentionally enforces the exact CLI
# version whose skills and schema are vendored in this package.
npm i -g @fission-ai/openspec@2.1.1
installed_version=$(openspec --version)
if [[ "$installed_version" != "2.1.1" ]]; then
  echo "expected openspec 2.1.1, got $installed_version" >&2
  exit 1
fi
echo "[openspec setup] openspec CLI 2.1.1 ready" >&2
