# 测试方法（可直接复用）

## 0. 一次测量的固定流水线

```
flush 全部 engine → warmup 共享前缀 → 压测 → analyze(steady) → 落盘 cmd/client.log/raw/analyze
```

任何一步缺失，点与点之间就不可比。

## 1. 单点压测（最常用）

```bash
bash scripts/run-point.sh <TAG> <DATASET_BASE> <RATE> <DURATION_S>
# 例：run-point.sh L77k90-r44 env-77k-h90-o600-n8192 44 600
```

- 开环用 `--rate`（泊松），闭路用 `--concurrency`；**两种不能混比**
- `--duration`：粗扫 150–180 s；**写结论必须 600 s**
- `--seed`：默认取 rate；边缘点换 145/245 复测
- warmup 行数 16、`--flush-url` 覆盖全部 engine

## 2. 48 点矩阵（evalscope）

- 维度：8k/64k/128k/256k × 0%/90% 命中 × c1/c8/c32/c64/c128/c256
- 每点 200–500 s；跑完用 `analysis.json` 抽指标（p50/p90/p99 + 每卡吞吐）
- **exact 前缀长度**要按设计校准（prefix_length/pages），否则"90% 命中"是假的

## 3. AgentX（真实轨迹）

- 官方 1 小时预设；固定接受长度 3.61（榜单口径）
- 会话粘性路由；每点错误数、TTFT/TPOT、缓存命中要一起记
- 报告口径与生产口径不同：AgentX 是"同交互性比吞吐"

## 4. 精度门禁

- GSM8K 1,319 题（lm-eval 固定 commit）+ needle 40 题（专压 DSA top-k）
- 理解检验力：±0.8pp，小于此的差异不构成结论；需要更严就用配对/扩样本

## 5. 复测与续跑

- 矩阵类任务支持断点续跑：看 `matrix.status.json`（done/total/failed/current）
- 复测沿用同一 `tag` + 新时间戳目录；导出表时用 tag 区分批次
- 失败点记录原因（如 `failed requests 5/258`），不要静默丢弃

## 6. 环境纪律

- JIT 缓存冷热必须一致（`cache/` 目录）
- 压测期间不要在同一节点跑其它 GPU 任务
- 记录 GPU 温度/功耗、邻接容器；跨天对比前先确认这些没变
