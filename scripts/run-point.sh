#!/usr/bin/env bash
# Run one immutable benchmark: flush → warmup → load → analyze.
# Usage: run-point.sh TAG DATASET RATE DURATION_S [GPU_COUNT]
set -euo pipefail

tag=${1:?usage: run-point.sh TAG DATASET RATE DURATION_S [GPU_COUNT]}
dataset=${2:?dataset name required}
rate=${3:?request rate required}
duration=${4:?duration in seconds required}
gpu_count=${5:-}

[[ $tag =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || {
  printf 'invalid tag; use letters, numbers, dot, underscore or dash\n' >&2
  exit 2
}

meta=${GT_META:-$PWD/.gpu-tuner/meta.env}
if [[ -f $meta ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$meta"
  set +a
fi

workspace=${GT_WORKSPACE:-}
image=${GT_IMAGE:-}
base_url=${GT_BASE_URL:-}
engines=${GT_ENGINES:-}
gpu_count=${gpu_count:-${GT_GPU_COUNT:-}}

for required in workspace image base_url gpu_count; do
  [[ -n ${!required} ]] || {
    printf 'missing %s; set metadata with scripts/init.sh\n' "$required" >&2
    exit 1
  }
done

dataset_file="$dataset.compact.jsonl"
warmup_file="$dataset.warmup.compact.jsonl"
if [[ ! -f $workspace/datasets/$dataset_file ]]; then
  dataset_file="$dataset.jsonl"
  warmup_file="$dataset.warmup.jsonl"
fi
[[ -f $workspace/datasets/$dataset_file ]] || {
  printf 'dataset not found: %s\n' "$workspace/datasets/$dataset_file" >&2
  exit 1
}

run_id=${RUN_ID:-"$(date -u +%Y%m%dT%H%M%SZ)-$(printf '%04x' "$RANDOM")"}
out="$workspace/results/$tag/$run_id"

bench_args=(
  /tools/bench_client.py
  --base-url "$base_url"
  --dataset "/data/ds/$dataset_file"
  --out /out/raw.jsonl
  --label "$tag/$run_id"
  --rate "$rate"
  --duration "$duration"
  --seed "${GT_SEED:-1}"
  --procs "${GT_CLIENT_PROCS:-1}"
)

if [[ -f $workspace/datasets/$warmup_file ]]; then
  bench_args+=(--warmup-file "/data/ds/$warmup_file" --warmup-concurrency "${GT_WARMUP_CONCURRENCY:-1}")
elif [[ ${ALLOW_NO_WARMUP:-0} != 1 ]]; then
  printf 'warmup dataset missing; set ALLOW_NO_WARMUP=1 only with a recorded justification\n' >&2
  exit 1
fi

if [[ -n $engines ]]; then
  read -r -a engine_list <<<"$engines"
  for engine in "${engine_list[@]}"; do
    [[ $engine == *=http://* || $engine == *=https://* ]] || {
      printf 'invalid GT_ENGINES entry: %s\n' "$engine" >&2
      exit 1
    }
    bench_args+=(--flush-url "${engine#*=}" --metrics-url "${engine#*=}")
  done
elif [[ ${ALLOW_NO_FLUSH:-0} != 1 ]]; then
  printf 'GT_ENGINES is empty; set ALLOW_NO_FLUSH=1 only with a recorded justification\n' >&2
  exit 1
fi

bench_cmd=(docker run --rm --init --network host --pull never --entrypoint python3
  -v "$workspace/tools:/tools:ro"
  -v "$workspace/datasets:/data/ds:ro"
  -v "$out:/out"
  "$image" "${bench_args[@]}")
analyze_cmd=(docker run --rm --init --network none --pull never --entrypoint python3
  -v "$workspace/tools:/tools:ro"
  -v "$out:/out"
  "$image" /tools/analyze.py /out/raw.jsonl --gpus "$gpu_count")

print_cmd() { printf ' %q' "$@"; printf '\n'; }
printf 'run_id=%s\nout=%s\nbench=' "$run_id" "$out"
print_cmd "${bench_cmd[@]}"
printf 'analyze='
print_cmd "${analyze_cmd[@]}"
[[ ${DRY_RUN:-0} == 1 ]] && exit 0

mkdir -p "$out"
{
  printf 'run_id=%q\n' "$run_id"
  printf 'tag=%q\n' "$tag"
  printf 'started_at=%q\n' "$(date -u +%FT%TZ)"
  printf 'dataset=%q\nrate=%q\nduration_s=%q\ngpu_count=%q\n' "$dataset_file" "$rate" "$duration" "$gpu_count"
  printf 'allow_no_flush=%q\nallow_no_warmup=%q\n' "${ALLOW_NO_FLUSH:-0}" "${ALLOW_NO_WARMUP:-0}"
} >"$out/metadata.env"
print_cmd "${bench_cmd[@]}" >"$out/bench.command.txt"
print_cmd "${analyze_cmd[@]}" >"$out/analyze.command.txt"

status=failed
trap 'printf "%s\n" "$status" >"$out/status"' EXIT
"${bench_cmd[@]}" >"$out/client.log" 2>&1
"${analyze_cmd[@]}" >"$out/analyze.txt" 2>&1
status=complete
tail -n 1 "$out/analyze.txt"
