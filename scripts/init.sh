#!/usr/bin/env bash
# Create a project-local .gpu-tuner/meta.env with shell-safe values.
# Usage: init.sh [--yes|--force|--show] [project_root]
set -euo pipefail

mode=interactive
force=0
project=""
while (($#)); do
  case "$1" in
    --yes) mode=batch ;;
    --force) force=1 ;;
    --show) mode=show ;;
    -*) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
    *) project=$1 ;;
  esac
  shift
done

project=${project:-$PWD}
meta_dir="$project/.gpu-tuner"
meta="$meta_dir/meta.env"

if [[ $mode == show ]]; then
  [[ -f $meta ]] || { printf 'no metadata: %s\n' "$meta" >&2; exit 1; }
  sed -E 's/^(([^#=]*(TOKEN|SECRET|PASSWORD|KEY)[^#=]*)=).*/\1<redacted>/I' "$meta"
  exit 0
fi

if [[ -f $meta && $force -ne 1 ]]; then
  printf 'metadata exists: %s (use --force to replace)\n' "$meta" >&2
  exit 1
fi

ask_value() {
  local name=$1 prompt=$2 fallback=${3-} value
  if [[ $mode == batch ]]; then
    value=${!name-}
  else
    read -r -p "$prompt${fallback:+ [$fallback]}: " value || true
    value=${value:-$fallback}
  fi
  printf '%s' "$value"
}

workspace=$(ask_value GT_WORKSPACE 'workspace containing tools/, datasets/, results/' "$project")
image=$(ask_value GT_IMAGE 'benchmark image or digest (required by run-point)' '')
engines=$(ask_value GT_ENGINES 'engine list: name=url separated by spaces' '')
base_url=$(ask_value GT_BASE_URL 'OpenAI-compatible endpoint' '')
gpu_count=$(ask_value GT_GPU_COUNT 'participating GPU count' '')

mkdir -p "$meta_dir"
umask 077
{
  printf '# gpu-serving-tuner metadata; local only; do not commit\n'
  printf '# generated_at=%s\n' "$(date -u +%FT%TZ)"
  printf 'GT_WORKSPACE=%q\n' "$workspace"
  printf 'GT_IMAGE=%q\n' "$image"
  printf 'GT_ENGINES=%q\n' "$engines"
  printf 'GT_BASE_URL=%q\n' "$base_url"
  printf 'GT_GPU_COUNT=%q\n' "$gpu_count"
} >"$meta"
chmod 600 "$meta"

printf 'written: %s\n' "$meta"
printf 'review values before running a benchmark; empty values have no defaults\n'
