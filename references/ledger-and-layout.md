# 目录结构、台账与脚本风格

目标：任何人（包括三个月后的你）打开目录，能在 **5 分钟**内回答：
这套服务怎么起、测的什么、每轮改了什么、当前结论与证据在哪。

## 1. 目录结构（按"角色"分，不按文件类型分）

```
<project>/
├── README.md                 入口：这是什么 + 四块导航（deploy/bench/results/analysis）
├── history.md                台账：唯一时间线（见 §2）
├── deploy/                   当前生效的部署（可执行 + 参数说明）
│   ├── README.md             拓扑 / 参数表 / 与上一版差异 / 起停命令
│   ├── scripts/              启动脚本（人类可读，见 §4）
│   ├── configs/              参数集中处：*.env、端口表、launch cmd 原文
│   └── inventory/            topology.md、versions.md
├── deploy-<变体>/            并列的其它方案（如 deploy-2p1d、deploy-pp4）
├── bench/                    测试脚本（与部署解耦，部署目录里不放压测逻辑）
│   ├── run-point.sh          单点：flush→warmup→压测→analyze
│   ├── run-matrix.sh         矩阵（48 点/回归集）
│   └── README.md             数据集、口径、门禁
├── results/                  原始结果，一次运行一个目录
│   └── <YYYYMMDD-HHMMSS>-<tag>/
│       ├── cmd.txt           可复现命令（含 rate/duration/seed）
│       ├── client.log       压测客户端输出
│       ├── raw.jsonl        逐请求原始记录
│       ├── analysis.json    稳态指标（p50/p90/p99、吞吐、错误）
│       └── summary.csv      导出的表格行（可选）
├── analysis/                 人写的分析
│   ├── iterations/           每轮迭代一页（见 §3，命名 NNN-<stack>-<date>.md）
│   ├── tables/               汇总表 + README（schema/tag/留空规则）
│   └── <topic>-deepdive.md   专题（机制、事故、复现方案…）
├── report/                   整包报告（PDF/DOCX + 版本说明）
├── .gpu-tuner/meta.env       首次初始化写入的环境元信息（**加入 .gitignore**）
└── MANIFEST.sha256           顶层校验和
```

约定：
- **results 目录名带 tag**，且 tag 与压测脚本里的 `TAG` 参数一致 → 从任何一行表格都能回到原始数据。
- 变体部署并列（`deploy-` 前缀），不要塞进主 `deploy/` 的子目录，否则"当前生效"会被稀释。
- 不把数据（raw.jsonl、模型、缓存）放进 `deploy/`；不把启动脚本放进 `bench/`。
- 台账只有一份（`history.md`），其它文档不写时间线。

## 2. 台账 `history.md` 的结构

顶部元信息（窗口 / 执行者 / 现场状态 / 硬约束），然后 7 节：

| 节 | 内容 | 写法要求 |
|---|---|---|
| 1 请求与结论 | `# / 请求 / 结论` 表 | 一条请求一行，结论给"已达成/部分/不可核验" |
| 2 时间线 | `时间 / 动作 / 关键结果` | 一行一个动作；结果带**文件路径或数字**；不写心路历程 |
| 3 信息记录 | 事实 + 证据 | 区分 **事实**（命令输出）与 **推断**（写"推断"） |
| 4 交付物 | 当前目录快照 | 路径 + 一句话；改名要写"旧→新" |
| 5 校验记录 | 做了什么校验、结果 | 如 `MANIFEST 247/247 OK`、`diff 为空` |
| 6 约束遵守 | 只读/零负载/不 commit 等 | 列出"做了什么"和"刻意没做什么" |
| 7 遗留问题 | 未决项 | 每条可执行（谁决定/需要什么数据） |

三条硬规则：
1. **追加不改写**：旧行保留原样；纠错时新增一行"更正：…"，并在旧行标注 `~~…~~`。
2. **结论必须可回溯**：任何"提升 X%"都要能指到 `results/<tag>/analysis.json` 或 `analysis/iterations/NNN-*.md`。
3. **每完成一批就补一行**，不要攒到最后回忆（回忆会失真）。

模板：`templates/history.md`。

## 3. 迭代记录 `analysis/iterations/NNN-<stack>-<date>.md`

每轮迭代一页，固定 6 段（模板见 `templates/iteration.md`）：

1. 目的与假设
2. 变量（单变量就写 1 个；栈式就列清单）
3. 对照组（baseline 的 results tag）
4. 结果表（同口径：p50/p90/p99 TTFT/TPOT + 每卡吞吐 + 错误数）
5. 结论：**保留 / 放弃 / 待定**，各附证据
6. 风险与下一步

命名 `003-cp4-chunk49k-20261111.md`：序号单调递增，便于"第几轮"一目了然。

## 4. 脚本风格（肉眼可读、尽量精简）

硬约束：
- **一个脚本只做一件事**，≤ 60 行；超过就拆成 `run-*.sh` + `up.sh`
- 顶部 3–6 行注释：用途 / 用法示例 / 依赖
- 所有环境相关值（镜像、路径、端口、HOST、GPU 列表）走变量或 `configs/*.env`
- `set -euo pipefail` + 必需变量检查（`: "${W:?set W}"`）
- **禁止**：`eval`、多层嵌套引号、运行时拼 shell、在脚本里 sleep 轮询健康（等待交给 `up.sh`）
- 输出只打印"下一步看哪里"（日志路径 / 健康 URL / 结果目录）
- 幂等：已存在容器直接拒绝并提示；`down.sh` 反序且默认 dry-run

推荐结构：

```bash
#!/usr/bin/env bash
# 用途：起 n1 上的 prefill 实例 P1（1 个容器）
# 用法：./10-n1-p1.sh          依赖：docker、镜像已存在、W/IMG 环境变量
set -euo pipefail
W=${W:?set W}; IMG=${IMG:?set IMG}
NAME=svc-p1
docker container inspect "$NAME" >/dev/null 2>&1 && { echo "already exists: $NAME" >&2; exit 1; }

docker run -d --name "$NAME" --gpus '"device=0,1,2,3"' \
  --network host --ipc host --shm-size 64g --ulimit memlock=-1 \
  --device /dev/infiniband --cap-add IPC_LOCK --pull never \
  -v "$W/models:/models:ro" -v "$W/cache:/root/.cache" \
  -e NCCL_IB_HCA=mlx5_0,mlx5_5,mlx5_8,mlx5_9 \
  "$IMG" python3 -m sglang.launch_server \
    --port 30000 --tp-size 4 --attn-cp-size 4 --enable-prefill-cp \
    --chunked-prefill-size 49152 --mem-fraction-static 0.86
echo "started $NAME; logs: docker logs -f $NAME"
```

反例（不要这样）：把 8 条 `docker run` 塞进一个脚本、`eval "$CMD"`、把路径与镜像写死在参数里、
用 `for` 循环拼字符串生成命令——改一个参数要读 200 行。

## 5. 和"生成式部署"的关系

如果现场是脚本生成 `.cmd` 再执行：
- 生成器（`launch*.sh`）留在 `deploy/`，一次性产物 `*.cmd` 存进 `deploy/configs/`（逐字节原文）；
- 手写启动脚本从 `.cmd` **程序化转写**（避免手抄引号/空格），转写后人工过一遍可读性；
- 两者不一致时，以现场 `.cmd` 为准，并在 `deploy/README.md` 里注明生成器的版本/时间。
