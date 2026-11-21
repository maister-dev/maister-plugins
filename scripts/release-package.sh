#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  echo "Usage: MAISTER_REPO=/path/to/mAIster $0 <package> <vX.Y.Z>" >&2
  exit 2
fi

package_name="$1"
version="$2"
tag="${package_name}/${version}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
maister_repo="${MAISTER_REPO:-}"

if [[ -z "$maister_repo" || ! -f "$maister_repo/web/package.json" ]]; then
  echo "MAISTER_REPO must point to a checkout containing web/package.json" >&2
  exit 2
fi

if [[ ! -d "$repo_root/packages/$package_name" ]]; then
  echo "Unknown package directory: packages/$package_name" >&2
  exit 2
fi

if [[ "$version" != v* ]]; then
  echo "Version must start with v (for example v2.6.0)" >&2
  exit 2
fi

if git -C "$repo_root" show-ref --verify --quiet "refs/tags/$tag"; then
  echo "Tag already exists: $tag" >&2
  exit 2
fi

if [[ -n "$(git -C "$repo_root" status --porcelain --untracked-files=all)" ]]; then
  echo "Release checkout must be clean so the gate validates exactly the tagged bytes" >&2
  exit 2
fi

pnpm --dir "$maister_repo" --filter maister-web validate:package-compatibility -- \
  --mode release \
  --source "$repo_root" \
  --tag "$tag"

# Native RAH contracts must survive the actual install/trust/enable pipeline.
# This gate consumes the clean candidate bytes, never the platform fixture copy.
if [[ "$package_name" == "rah" ]]; then
  NATIVE_RAH_CANDIDATE="$repo_root/packages/rah" NATIVE_RAH_VERSION="$tag" \
    pnpm --dir "$maister_repo" --filter maister-web test:integration \
    lib/packages/__tests__/native-rah.integration.test.ts
fi

git -C "$repo_root" tag -a "$tag" -m "Release $tag"
