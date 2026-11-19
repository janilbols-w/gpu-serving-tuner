# gpu-serving-tuner

用于 GPU/LLM 推理服务的部署盘点、recipe 整理、基准测试、瓶颈诊断与调优复盘的 Codex skill。

它强调三件事：先建立可复现基线，再通过分层门禁验证实验，最后把命令、原始结果与决策整理成可审计且脱敏的证据链。

## 能处理的任务

- 从实际 argv、进程环境、镜像和挂载生成部署快照；
- 将散落启动脚本整理为按引擎或来源区分的最小 recipe；
- 设计 smoke、anchor、短测、边界复测和长稳态测试；
- 诊断 TTFT、TPOT、吞吐、失败率和容量问题；
- 设计单变量实验、并行探索臂和晋级门禁；
- 复核性能报告与原始数据是否一致；
- 建立 run ledger、迭代记录、推荐入口和脱敏发布包。

## 目录

```text
gpu-serving-tuner/
├── SKILL.md
├── references/
│   ├── capture-deploy.md
│   ├── documentation-and-sanitization.md
│   ├── engineering-workflow.md
│   ├── ledger-and-layout.md
│   ├── metrics-and-trust.md
│   ├── rapid-iteration.md
│   ├── script-and-recipe-design.md
│   ├── table-schema.md
│   ├── testing-recipes.md
│   └── tuning-playbook.md
├── scripts/
│   ├── init.sh
│   ├── run-point.sh
│   └── extract-metrics.py
├── templates/
│   ├── TAG
│   ├── deploy-readme.md
│   ├── history.md
│   └── iteration.md
└── examples/table-schema.example.csv
```

## 使用

先让 Agent 按 `SKILL.md` 选择 Capture、Curate、Benchmark、Tune、Diagnose 或 Review 模式。只有需要运行配套脚本时才初始化项目元数据：

```bash
bash scripts/init.sh /path/to/project
```

非交互模式只写已提供的值，不填环境相关的“合理默认值”：

```bash
GT_WORKSPACE=/path/to/workspace \
GT_BASE_URL=http://127.0.0.1:8000 \
GT_ENGINES='p=http://127.0.0.1:30000' \
bash scripts/init.sh --yes /path/to/project
```

单点压测使用唯一 run-id，默认会要求 flush 与 warmup 命令存在：

```bash
bash scripts/run-point.sh <tag> <dataset> <rate> <duration-seconds>
DRY_RUN=1 bash scripts/run-point.sh <tag> <dataset> <rate> <duration-seconds>
```

配套脚本假设项目提供 `tools/bench_client.py`、`tools/analyze.py`，以及可选的 `tools/flush.py`、`tools/warmup.py`。接入其他压测器时保留相同阶段语义即可。

## 安装边界

`install.sh` 会把 skill 复制到指定项目的 `.dsh/skills/gpu-serving-tuner`。请先审阅并运行 `make check`，再执行安装；本仓库的更新不会自动覆盖任何已安装副本。

## 验证

```bash
make check
```

## 信息安全

仓库不得包含真实用户名、主机名、私网 IP、绝对内部路径、私有镜像、凭据、客户/项目代号、内部价格或未公开性能数据。样例必须使用占位符或明确标记的合成数据。

## License

MIT，见 `LICENSE`。
