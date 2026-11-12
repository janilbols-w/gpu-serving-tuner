---
name: gpu-serving-tuner
description: 面向 LLM 推理服务（SGLang/vLLM/Dynamo 等）的部署盘点、性能对比与调优复盘流程：只读抓取部署参数、按 SLO 口径压测、归因 TTFT/TPOT、设计单变量实验、判断数据可信度，并把结果归档成 deploy/analysis/tables/report 四件套。当用户要「盘点服务/记录部署参数/对比两套方案/分析 TTFT/TPOT/做性能报告/核对报告数字/复测」时使用。
---

# GPU 推理服务：部署盘点 + 调优复盘

把「一套服务现在怎么配的、比上一套好在哪、数字可不可信」变成可重复的流程。所有步骤默认**只读**，除非用户明确要求改动。

## 触发场景

- 新部署上线，要记录参数、和旧方案对比
- TTFT / TPOT / 吞吐异常，要定位瓶颈
- 要复核一份性能报告里的数字
- 要把散落的测试结果整理成表/报告/归档

## 首次使用：向用户要这份 meta

不要从目录结构猜配置。第一次使用时，一次性问清下面 8 项（可批量问，用户答完即写入 `.gpu-tuner/meta.env`）：

| 需要问的 | 写入变量 | 例 |
|---|---|---|
| 工作区根目录（实际执行机上） | `GT_WORKSPACE` | `/path/to/workspace` |
| 引擎镜像（原样 tag） | `GT_IMAGE` | `registry/engine:tag` |
| flush/metrics 的 engine 列表 | `GT_ENGINES` | `p1=http://host:30000 p2=...` |
| 压测入口 | `GT_BASE_URL` | `http://127.0.0.1:8000` |
| 节点数 / 每节点 GPU | `GT_NODES` / `GT_GPUS_PER_NODE` | `4` / `8` |
| SLO 三阈值 | `GT_SLO_TTFT_P50/P99`、`GT_SLO_TPOT_P90` | `2.5` / `5` / `20` |
| 目录价（新输入/命中/输出） | `GT_PRICE_FRESH/CACHED/OUTPUT` | `8` / `2` / `28` |
| 目标月收入 | `GT_TARGET_MONTH` | `24000000` |

规则：
- **缺一项就停下来问**，不要填"合理默认值"后继续（错误的路径会让后面所有数据作废）；
- 用户不想逐项答时，可先只给工作区与镜像，其余留默认并在台账里注明"默认值"；
- meta 只写进 `.gpu-tuner/meta.env`（已 gitignore、600 权限），不要写进 README 或脚本。

## 核心循环（0–7 步）

0. **初始化 + 建骨架（首次使用必须问用户）**：
   - 先查 `<project>/.gpu-tuner/meta.env`；不存在就**逐项向用户索取**（不要猜路径、镜像、端口，也不要从目录里推断）：
     工作区根目录、引擎镜像、flush/metrics 的 engine 列表、压测入口 URL、节点数/每节点 GPU 数、SLO 三阈值、目录价、目标月收入。
   - 拿到后写 meta：`GT_IMAGE=... GT_WORKSPACE=... bash scripts/init.sh --yes`（脚本会落 `.gpu-tuner/meta.env` 并 chmod 600）；
     之后 `run-point.sh` 等脚本自动读取，不需要再传参。
   - 同时按 `references/ledger-and-layout.md` 建 `deploy/ bench/ results/ analysis/ report/` + `history.md`（模板见 `templates/`），先有台账再干活。
1. **冻结目标**：写清 SLO（TTFT p50/p99、TPOT p90…）、计价口径、指标定义、可接受误差。没有 SLO 的"提升"无法判定。
2. **只读盘点**：容器 → 引擎进程 args → 进程环境 → 挂载/模型 → KV dtype/传输/路由 → 机器拓扑。产出部署档案（见 `references/capture-deploy.md`）。
3. **建基线**：每个负载点按「flush → warmup → 压测 → analyze」跑；矩阵类用 evalscope 扫 48 点；同时跑精度门禁。
4. **归因**：TTFT 拆成 排队 / prefill 计算 / KV 传输 / 首个 decode step；TPOT 拆成 verify / draft。看 `keeps_up` 判断是否已过载。
5. **单变量实验**：水平型变量（策略、配方、布局）做 3 档 A/B；栈式优化一次只加一层。**短测找 knee，10 分钟定边界**，失败退一档。
6. **决策**：SLO 优先 → 同 SLO 下比收入/每卡吞吐 → 看复杂度代价（无稳定收益就"关配置、留代码"）。
7. **归档**：deploy / bench / results / analysis / report + MANIFEST + **台账**；报告数字逐项可复算，缺原始数据的标"不可核验"。
   台账与目录规范见 `references/ledger-and-layout.md`，模板见 `templates/`（history.md / iteration.md / deploy-readme.md）。

## 目录、台账与脚本（贯穿全程）

**目录按角色分**：`deploy/`（怎么起）、`bench/`（怎么测）、`results/`（原始数据，目录名带 tag）、
`analysis/`（怎么解读，含 `iterations/` 每轮一页）、`report/`（对外）、`history.md`（唯一时间线）。
变体部署用并列的 `deploy-<变体>/`，不要塞进主 deploy。

**台账三条硬规则**：追加不改写（纠错用"更正："新增一行）；每条结论必须能指到 `results/<tag>` 或
`analysis/iterations/NNN-*.md`；每完成一批就补一行，不攒到最后回忆。

**脚本风格（肉眼可读）**：一个脚本只做一件事、≤60 行；顶部 3–6 行注释（用途/用法/依赖）；
镜像/路径/端口全部走变量或 `configs/*.env`；禁止 `eval`、嵌套引号、运行时拼 shell；
等待与健康检查放 `up.sh`，压测放 `bench/`；`down.sh` 反序且默认 dry-run。
详细规范与正反例见 `references/ledger-and-layout.md`。

## 第 1 步：冻结目标（先写再做）

| 项 | 示例 |
|---|---|
| SLO | TTFT p50 ≤ 2.5 s、p99 ≤ 5 s、TPOT p90 ≤ 20 ms |
| 吞吐口径 | 每卡总吞吐 = (输入含命中 + 输出) / 时长 / GPU 数 |
| 经济口径 | 目录价（示例 8/2/28 元每百万 token）；CNY/GPU-h；目标 X 万元/32 卡月 |
| 数据可信度 | 吞吐 ±1%；p99 单跑 ±40%；边界 ±1 档（详见 `references/metrics-and-trust.md`） |

## 第 2 步：只读盘点（不许有负载）

见 `references/capture-deploy.md`。要点：

- **引擎参数以进程 cmdline 为准**（容器 `sleep infinity` 时 `docker inspect .Config.Cmd` 是壳，不是服务）
- **环境变量看 `/proc/<pid>/environ`**（`engine_env.sh` source 的变量不会出现在容器 env 里）
- **KV dtype 以启动日志的 `server_args` 为准**（`kv_cache_dtype=auto` ≠ fp8）
- 记录：镜像 ID、代码 commit、模型路径、并行度、chunk、max-running、mem-fraction、缓存层、传输后端、路由策略、每卡 rail 映射

## 第 3 步：测量

固定流水线，缺一步数据就不可比：

```
flush 所有 engine → warmup 共享前缀(16 行) → 压测(开环泊松/闭路并发) → analyze(steady 窗口)
```

- 单点：`bash scripts/run-point.sh <tag> <dataset> <rate> <duration>`
- 矩阵：evalscope 48 点（8k/64k/128k/256k × 0%/90% × c1–c256）
- 精度门禁：GSM8K + needle，每次代码/量化变更后跑
- 详见 `references/testing-recipes.md`

## 第 4 步：归因（先看谁先破）

先统计失败点的触发指标：在多次实测中，约 **3/4 的失败点是 TTFT 先破**（p50 与 p99 同时超），TPOT 单独破只占个位数百分比。结论：**主战场通常在 prefill**，decode 只做参数收敛。

| 现象 | 大概率原因 | 先查 |
|---|---|---|
| TTFT p50 高、p99 也高 | prefill 排队/计算慢 | chunk 大小、prefill 并行度、P 并发槽 |
| 仅 TTFT p99 高 | 长尾抖动（传输/调度） | KV 传输、bootstrap、路由 |
| TPOT p90 高 | decode 批太满 | max-running、graph bs、mem-fraction |
| keeps_up=false | 已过载 | 该点延迟无意义，先降档 |

## 第 5 步：调优项与量级（经验值，需按环境复测）

| 方向 | 做法 | 预期 | 风险 |
|---|---|---|---|
| prefill 并行范式 | PP（切层，串行段）→ CP（切 token，并行） | **量级收益**（单卡 prefill 工作量约 ÷CP） | CP 需 packed top-k、每层 all-gather |
| 分块 | chunk 8k → 49k | 长 prompt 少几百 ms ~ 秒 | 首块延迟变大、显存峰值 |
| P 并发槽 | max-running 16 → 32 | 大队列时 p95/p99 明显改善 | 单请求可能变慢 |
| D 端 radix | 打开前缀复用 | 多轮 KV 传输量 ~10×↓ | 需正确性补丁 |
| KV dtype | bf16 → fp8 | 带宽/容量翻倍收益 | 精度、需量化路径 |
| HiCache | 2P1D 开、3P1D 关 | 命中率↑ 但命中路径 +延迟 | host 容量/同步复杂度 |
| early headers | prefill 首 chunk 前回包 | p50 −20% 量级 | 校验错误只能走 SSE |
| 路由 | rr / least_load / 亲和 | rr 常优于 least_load | 负载估计滞后 |
| FP8 子模块、packed top-k | 加载期量化 / 打包 top-k | 1–3% | 精度门禁 |
| MegaMoE 预留 SM | 32 → 2 | 同负载 p50 −15% 量级 | 需重测 |
| 投机参数 | steps/draft 数 | 只影响 TPOT，不影响 TTFT | 接受长度口径要统一 |

## 第 6 步：决策规则

1. 任一分位超 SLO → 该点 FAIL，不进候选
2. 失败退一档重测，直到稳定
3. 同 SLO 比收入（或每卡输出吞吐），不比"总吞吐"（含缓存命中输入会失真）
4. 新机制若无稳定收益 → 配置关闭、代码保留
5. 精度门禁不过 → 回滚该改动

## 第 7 步：反模式（踩过的坑）

| 反模式 | 后果 |
|---|---|
| 用 3 分钟短测当边界 | 高估 5–7%，p99 尤其 |
| 单次运行下结论 | p99 波动 ±40% |
| 混口径比较（不同 ISL/命中/生成器/卡数） | 结论不可比，必须换算到"同 p50 的吞吐"或"同吞吐的 p99" |
| 用 fake-PD / simulate-acc 的数据当生产结论 | 它们只是测量工具 |
| 只报 p50 或只报平均 | 掩盖长尾 |
| 跨命中率比"总吞吐" | 输出占比可能只有 0.8%，指标含义变了 |
| 未记录 JIT 缓存冷热/温度/邻机占用 | 跨天对比不可信 |

## 交付物布局

```
deploy-<方案>/            部署档案：README(参数+差异) / launch-record(.cmd原文) / scripts(起停) / inventory(拓扑)
analysis/                 复盘：journey / methodology / metrics-definition / verification / incident / <对比>.md
analysis/tables/          测试数据汇总（模板 72 列 + tag + 备注）
report/                   整包报告 PDF/DOCX + 版本说明
MANIFEST.sha256           顶层校验和；raw/ 类镜像目录自带独立清单
history.md                台账：时间线、动作、证据、校验、遗留问题
```

表格 schema 与 tag 规范见 `references/table-schema.md`。

## 完成标准（checklist）

- [ ] 部署参数来自引擎 cmdline + `/proc/<pid>/environ`，不是容器壳
- [ ] 每个结论都标了口径（负载、命中、卡数、时长）
- [ ] 关键边界点 ≥1 次 10 分钟确认；理想 3 seed
- [ ] 精度门禁跑过，并理解 1,319 题 ±0.8pp 的检验力上限
- [ ] 报告数字与原始 summary 逐项对过；不可核验项已标注
- [ ] 目录有 MANIFEST、台账有记录、文档相对链接可解析
- [ ] `analysis/iterations/` 每轮一页，结论三态（保留/放弃/待定）齐全
- [ ] 启动脚本 ≤60 行、参数走变量、无 eval；`results/` 目录名与 tag 一致
- [ ] 首次使用已生成 `.gpu-tuner/meta.env`（无硬编码路径/镜像），且该文件未被提交
