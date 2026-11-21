#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <project-slug>" >&2
  exit 64
fi

project_slug=$1
case "$project_slug" in
  ''|*[!A-Za-z0-9._-]*)
    echo "invalid project slug: $project_slug" >&2
    exit 65
    ;;
esac

if ! command -v uv >/dev/null 2>&1; then
  echo "BMAD CIS v0.3.2 requires uv with Python 3.11+" >&2
  exit 69
fi

project_root=$(pwd -P)
skill_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
scripts_dir="$project_root/_bmad/scripts"
config_file="$project_root/_bmad/config.toml"
cis_config="$project_root/_bmad/cis/config.yaml"

mkdir -p "$scripts_dir" "$project_root/_bmad/cis" "$project_root/docs/planning-artifacts" "$project_root/docs/discovery"
cp "$skill_root/scripts/config_utils.py" "$scripts_dir/config_utils.py"
cp "$skill_root/scripts/resolve_customization.py" "$scripts_dir/resolve_customization.py"

if [ ! -f "$config_file" ]; then
  printf '%s\n' \
    '[core]' \
    "project_name = \"$project_slug\"" \
    'user_name = "MAIster"' \
    'communication_language = "English"' \
    'document_output_language = "English"' \
    'output_folder = "docs"' \
    > "$config_file"
elif ! grep -Eq '^\[core\][[:space:]]*$' "$config_file"; then
  printf '\n' >> "$config_file"
  printf '%s\n' \
    '[core]' \
    "project_name = \"$project_slug\"" \
    'user_name = "MAIster"' \
    'communication_language = "English"' \
    'document_output_language = "English"' \
    'output_folder = "docs"' \
    >> "$config_file"
fi

if [ ! -f "$cis_config" ]; then
  printf '%s\n' \
    "project_name: \"$project_slug\"" \
    'user_name: "MAIster"' \
    'communication_language: "English"' \
    'document_output_language: "English"' \
    'output_folder: "docs"' \
    'visual_tools: "intermediate"' \
    > "$cis_config"
fi

echo "[cis substrate] BMAD CIS v0.3.2 runtime ready"
