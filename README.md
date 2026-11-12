# gpu-serving-tuner

一套可复用的 **LLM 推理服务部署盘点 / 性能对比 / 调优复盘** 流程，打包成 DSH（DeepSeek Harness）Skill。
它把「这套服务怎么配的、比上一套好在哪、数字可不可信」变成可重复的 7 步循环，并附带只读采集清单、度量口径与可信度阈值、测试配方、制表规范，以及两个可直接用的脚本。

> 适用对象：SGLang / vLLM / Dynamo / TensorRT-LLM 等 OpenAI 兼容推理服务的 SRE、性能工程师、做容量规划的人。

## 它解决什么问题

- 新服务上线，需要**记录部署参数**并与旧方案对比 → 参数只认进程 cmdline 与 `/proc/<pid>/environ`，不认“文档”
- TTFT / TPOT 异常，需要**定位瓶颈** → 先看哪个分位先破；77% 的失败点其实是 TTFT 先破
- 需要判断**数据可信度** → 短测高估多少、p99 抖动多大、精度差异是否显著，都有量化阈值
- 需要把结果**归档成可交付物** → deploy / analysis / tables / report 四件套 + 校验和 + 台账

## 快速开始

```bash
# 1) 安装到某个项目的 .dsh/skills（项目级）
bash install.sh /path/to/your/project

# 2) 首次初始化：写入本集群的 meta（工作区/镜像/端点/SLO/价格）
#    交互式：
bash scripts/init.sh /path/to/your/project
#    或无人值守（把值从环境变量灌进去）：
GT_WORKSPACE=... GT_IMAGE=... GT_ENGINES="p1=http://host:30000" \
  bash scripts/init.sh --yes /path/to/your/project

# 3) 之后在项目里让 Agent 使用
#    “按 gpu-serving-tuner 流程盘点这套服务”
```

meta 写入 `<project>/.gpu-tuner/meta.env`（600 权限、已 gitignore）。没有它时脚本会拒绝运行并提示先初始化——
**技能不会猜你的路径和镜像**。

也可以直接把 `gpu-serving-tuner/` 目录放进你的 Agent 的技能目录。

## 包内容

```
gpu-serving-tuner/
├── SKILL.md                     7 步流程 + 调优项量级 + 决策规则 + 反模式 + 完成标准
├── references/
│   ├── capture-deploy.md        只读盘点：容器→进程 cmdline→/proc environ→日志 server_args→rail
│   ├── metrics-and-trust.md     指标公式（TTFT/TPOT/ITL/steady/keep-up/收入）+ 可信度阈值表
│   ├── testing-recipes.md       flush→warmup→压测→analyze；48 点矩阵；AgentX；精度门禁；复测续跑
│   ├── table-schema.md          72 列测试汇总表 schema + tag 规范 + 留空规则
│   └── ledger-and-layout.md     目录结构 + 台账写法 + 脚本风格（含正反例）
├── scripts/
│   ├── init.sh                  首次初始化：交互/批量写入 .gpu-tuner/meta.env
│   ├── run-point.sh             单点压测（自动读 meta，跑完 analyze）
│   └── extract-metrics.py       从 analysis.json / raw.summary.json 批量抽指标成 CSV
├── templates/                   可直接复制的骨架：history / iteration / deploy-readme
├── examples/table-schema.example.csv   表的列示例（3 行）
├── install.sh                   安装到项目的 .dsh/skills
├── LICENSE (MIT) · CHANGELOG.md · .gitignore
```

## 7 步循环（详见 SKILL.md）

1. 冻结目标（SLO / 口径 / 可接受误差）
2. 只读盘点（引擎 cmdline、进程环境、KV dtype、传输/路由、rail）
0. 建骨架（目录 + 台账模板）
3. 建基线（flush→warmup→压测→analyze；矩阵 + 精度门禁）
4. 归因（TTFT 四段、TPOT 两段、`keeps_up`）
5. 单变量实验（水平变量 3 档 A/B；栈式一次一层；短测找 knee、10 分钟定边界）
6. 决策（SLO 优先 → 同 SLO 比收入 → 无稳定收益则关配置留代码）
7. 归档（deploy/bench/results/analysis/report + MANIFEST + 台账；每轮一页迭代记录）

## 用之前要知道的边界

- **测量工具比结论更重要**：没有固定的 flush/warmup/analyze 流水线，点与点不可比。
- **统计功效有限**：单跑 p99 波动约 ±40%；1,319 题 GSM8K 的 stderr ≈ 0.4pp，小于 0.8pp 的差异不显著。
- **不同口径不能混比**：不同 ISL/命中率/卡数/生成器之间，只能比“同 p50 的吞吐”或“同吞吐的 p99”。
- **仿真实测量工具不是生产结论**：fake-PD、固定接受长度只用于解耦测量。

## 适配自己的环境

| 变量 | 用途 |
|---|---|
| `GT_WORKSPACE`（或 `W`） | 工作区根目录（含 `tools/`、`datasets/`、`results/`） |
| `GT_IMAGE`（或 `IMG`） | 引擎镜像 |
| `GT_ENGINES`（或 `ENGINES`） | `name=http://host:port` 列表，用于 flush/metrics |
| `GT_BASE_URL`（或 `BASE_URL`） | 压测入口（默认 `http://127.0.0.1:8000`） |
| `WARMUP_CONCURRENCY` | warmup 并发（默认 16） |

脚本假设 `tools/bench_client.py`、`tools/analyze.py` 存在（SGLang 生态常用压测工具）；换成自己的压测器时，保留“flush → warmup → 压测 → 稳态分析”的语义即可。

## 贡献

欢迎提交 PR 补充：新的压测器适配、更多 SLO 口径、可信度阈值的实测数据。
请勿提交任何**客户数据、内部吞吐数字、私有镜像地址**。

## License

MIT（见 LICENSE）。
