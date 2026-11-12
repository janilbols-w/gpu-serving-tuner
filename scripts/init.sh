#!/usr/bin/env bash
# 首次初始化：收集本集群的元信息，写入 <project>/.gpu-tuner/meta.env
# 用法：
#   交互：bash scripts/init.sh [project_root]
#   无人值守：GT_WORKSPACE=... GT_IMAGE=... ... bash scripts/init.sh --yes [project_root]
#   查看  ：bash scripts/init.sh --show
#   重写  ：bash scripts/init.sh --force
set -euo pipefail
MODE=interactive; PROJECT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) MODE=batch ;;
    --force) MODE=force ;;
    --show) MODE=show ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) PROJECT=$1 ;;
  esac; shift
done
PROJECT=${PROJECT:-$PWD}
META_DIR="$PROJECT/.gpu-tuner"; META="$META_DIR/meta.env"

if [ "$MODE" = show ]; then
  [ -f "$META" ] && cat "$META" || { echo "no meta at $META" >&2; exit 1; }
  exit 0
fi
if [ -f "$META" ] && [ "$MODE" != force ]; then
  echo "已存在：$META（--force 重写 / --show 查看）"; exit 0
fi

ask() { # name  default  prompt
  local name=$1 def=${2-} prompt=$3 ans
  if [ "$MODE" = batch ]; then
    ans="${!name:-$def}"
  else
    read -r -p "$prompt [$def]: " ans || true
    ans=${ans:-$def}
  fi
  printf '%s=%s\n' "$name" "$ans"
}

mkdir -p "$META_DIR"
{
  echo "# gpu-serving-tuner meta — 首次初始化生成，请勿提交（已在 .gitignore）"
  echo "# generated: $(date -u +%FT%TZ)"
  ask GT_WORKSPACE        "$PROJECT"                    "工作区根目录（放 tools/、datasets/、results/）"
  ask GT_IMAGE            "${GT_IMAGE:-}"               "引擎镜像（原样 tag，如 registry/engine:tag）"
  ask GT_ENGINES          "${GT_ENGINES:-}"             "flush/metrics 用 engine 列表（name=http://host:port，空格分隔）"
  ask GT_BASE_URL         "${GT_BASE_URL:-http://127.0.0.1:8000}" "压测入口 URL"
  ask GT_NODES            "${GT_NODES:-4}"              "节点数"
  ask GT_GPUS_PER_NODE    "${GT_GPUS_PER_NODE:-8}"      "每节点 GPU 数"
  ask GT_SLO_TTFT_P50     "${GT_SLO_TTFT_P50:-2.5}"     "SLO：TTFT p50 上限（秒）"
  ask GT_SLO_TTFT_P99     "${GT_SLO_TTFT_P99:-5}"       "SLO：TTFT p99 上限（秒）"
  ask GT_SLO_TPOT_P90     "${GT_SLO_TPOT_P90:-20}"      "SLO：TPOT p90 上限（毫秒）"
  ask GT_PRICE_FRESH      "${GT_PRICE_FRESH:-8}"        "目录价：新输入（元/百万 token）"
  ask GT_PRICE_CACHED     "${GT_PRICE_CACHED:-2}"       "目录价：缓存命中输入（元/百万 token）"
  ask GT_PRICE_OUTPUT     "${GT_PRICE_OUTPUT:-28}"      "目录价：输出（元/百万 token）"
  ask GT_TARGET_MONTH     "${GT_TARGET_MONTH:-24000000}" "目标收入（元 / 32 卡月）"
} > "$META"
chmod 600 "$META"
echo "written: $META"
echo "next: bash scripts/run-point.sh <TAG> <DATASET_BASE> <RATE> <DURATION>"
