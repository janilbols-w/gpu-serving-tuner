# 台账与目录布局

## 推荐结构

```text
project/
├── launch/
│   ├── sglang/
│   ├── vllm/
│   └── <source>_<engine>/
├── bench/
├── results/<tag>/<run-id>/
├── analysis/
│   ├── iterations/
│   └── tables/
├── plans/
├── report/
├── history.md
└── MANIFEST.sha256
```

启动脚本与压测脚本分离。原始结果不可变；分析和报告通过 run-id 引用它们。

## Tag 与 run-id

Tag 表达可读实验组，推荐 `<mode>-<workload>-<variant>`。run-id 表达一次实际执行，推荐 UTC 时间加短随机串，例如 `20270102T030405Z-a1b2`。

不要把主机名、用户名、客户代号或私有模型名编码进 tag。相同 tag 可以有多个 run-id，不能覆盖。

## history.md

history 是只追加时间线。每行至少包含：时间、动作、config-id/run-id、状态、证据链接和一句决策。更正通过新增记录完成，不改写旧记录。

## iteration 页

每轮记录：假设、基线、唯一变量或 bundle、固定条件、测试层级、结果、有效性门禁、解释、决策和下一步。失败实验同样记录，因为它定义了边界。

## 推荐入口

同一硬件、运行时、负载和 SLO 范围内可以提供 `recommended` 文档或符号指针，并写清选择理由。跨模式只给索引和适用条件，不维护一个全局最佳。

## 完整性

- 目录内使用相对链接；
- 报告数字链接到 table 行和 run-id；
- 交付时生成清单或校验和；
- 原始大结果如不进入仓库，记录外部位置的脱敏标识和校验值；
- 不保留孤立脚本、空实现目录或无法解释的二进制。

## 最小可复现包

只保留启动与理解启动所需的内容：README、配置模板、start/stop/status、必要 patch 说明、负载定义和少量合成样例。排除权重、数据集、wheel、镜像、缓存、大日志和真实性能结果。
