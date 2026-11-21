#!/usr/bin/env bash
set -euo pipefail

if command -v specify >/dev/null 2>&1 && specify version --features | grep -Fx 'Spec Kit CLI: 1.4.3'; then
  exit 0
fi
if command -v uv >/dev/null 2>&1; then
  uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v1.4.3
elif command -v pipx >/dev/null 2>&1; then
  pipx install --force 'git+https://github.com/github/spec-kit.git@v1.4.3'
else
  echo 'Spec Kit 1.4.3 requires uv or pipx for installation' >&2
  exit 1
fi
specify version --features | grep -Fx 'Spec Kit CLI: 1.4.3'
