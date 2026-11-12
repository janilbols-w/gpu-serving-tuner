#!/usr/bin/env bash
# 单点压测：flush → warmup → 压测 → analyze
# 用法: run-point.sh <TAG> <DATASET_BASE> <RATE> [DURATION_S] [GPUS]
set -euo pipefail
TAG=${1:?usage: run-point.sh TAG DATASET_BASE RATE [DURATION] [GPUS]}
DS=${2:?dataset base name}; RATE=${3:?rate}; DUR=${4:-180}; GPUS=${5:-32}

# 元信息：优先环境变量，其次 <project>/.gpu-tuner/meta.env（首次运行 scripts/init.sh 生成）
META=${GT_META:-$PWD/.gpu-tuner/meta.env}
if [ -f "$META" ]; then set -a; . "$META"; set +a; fi
IMG=${IMG:-${GT_IMAGE:-}}
W=${W:-${GT_WORKSPACE:-}}
BASE_URL=${BASE_URL:-${GT_BASE_URL:-http://127.0.0.1:8000}}
ENGINES=${ENGINES:-${GT_ENGINES:-}}
[ -n "$IMG" ] || { echo "IMG 未设置：先运行 bash scripts/init.sh（或导出 GT_IMAGE）" >&2; exit 1; }
[ -n "$W" ]   || { echo "W 未设置：先运行 bash scripts/init.sh（或导出 GT_WORKSPACE）" >&2; exit 1; }
OUT=$W/results/$TAG; mkdir -p "$OUT"
FL=""; MU=""
for e in $ENGINES; do FL="$FL --flush-url ${e#*=}"; MU="$MU --metrics-url ${e#*=}"; done
DSF=$DS.compact.jsonl; WF=$DS.warmup.compact.jsonl
[ -f "$W/datasets/$DSF" ] || { DSF=$DS.jsonl; WF=$DS.warmup.jsonl; }
WARM=""; [ -f "$W/datasets/$WF" ] && WARM="--warmup-file /data/ds/$WF --warmup-concurrency ${WARMUP_CONCURRENCY:-16}"
echo "$(date -u +%FT%TZ) $TAG $DS rate=$RATE dur=$DUR" > "$OUT/cmd.txt"
docker run --rm --init --network host --pull never --entrypoint python3 \
  -v "$W/tools:/tools:ro" -v "$W/datasets:/data/ds:ro" -v "$OUT:/out" "$IMG" \
  /tools/bench_client.py --base-url "$BASE_URL" --dataset "/data/ds/$DSF" --out /out/raw.jsonl \
  $WARM $FL $MU --label "$TAG" --rate "$RATE" --duration "$DUR" --seed "$RATE" --procs 4 \
  > "$OUT/client.log" 2>&1
docker run --rm --init --network none --pull never --entrypoint python3 \
  -v "$W/tools:/tools:ro" -v "$OUT:/out" "$IMG" \
  /tools/analyze.py /out/raw.jsonl --gpus "$GPUS" > "$OUT/analyze.txt" 2>&1
tail -1 "$OUT/analyze.txt"
