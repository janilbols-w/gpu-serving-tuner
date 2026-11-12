# Changelog

## 1.2.0 — 2026-11-12

- **首次初始化交互**：新增 `scripts/init.sh`，把工作区/镜像/端点/节点数/SLO/价格等写入
  `.gpu-tuner/meta.env`（600 权限、gitignore）；`run-point.sh` 自动读取，缺 meta 时拒绝运行
- SKILL.md 新增「首次使用：向用户要这份 meta」小节与第 0 步的索取清单（**禁止猜路径与镜像**）
- **脱敏**：移除内部方案名与可回溯的示例数值；示例表改为明确的构造数据；价格标注为"示例"配置

## 1.1.0 — 2026-11-12

新增"可追溯"能力（来自一次多轮调优的实际台账）：

- `references/ledger-and-layout.md`：目录结构规范（deploy/bench/results/analysis/report）、
  台账 `history.md` 的 7 节结构与三条硬规则、迭代记录 `NNN-*.md` 的 6 段结构、
  **脚本风格规范**（≤60 行、参数走变量、禁止 eval、等待与压测分离）+ 正反例
- `templates/`：`history.md`、`iteration.md`、`deploy-readme.md` 三个可直接复制的骨架
- SKILL.md 增加第 0 步"建骨架"，并把台账/目录/脚本要求写进完成标准

## 1.0.0 — 2026-11-12

首个公开发布，从一次真实的多机 PD 分离服务调优中沉淀：

- 7 步循环（目标 → 盘点 → 基线 → 归因 → 实验 → 决策 → 归档）
- 只读采集清单（进程 cmdline / `/proc/<pid>/environ` / 日志 `server_args` / rail 映射）
- 度量口径与可信度阈值（吞吐 ±1%、p99 ±40%、短测高估 5–7%、窗口内漂移 25–51%、GSM8K ±0.8pp）
- 测试配方（单点、48 点矩阵、AgentX、精度门禁、复测续跑）
- 72 列测试汇总表 schema + tag 规范
- 脚本：`run-point.sh`、`extract-metrics.py`
