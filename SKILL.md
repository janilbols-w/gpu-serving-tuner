---
name: gpu-serving-tuner
description: 面向 GPU/LLM 推理服务的可复现部署整理、基准测试、瓶颈诊断和调优复盘。适用于 SGLang、vLLM、Dynamo、TensorRT-LLM 等服务；当用户要盘点启动参数、整理 recipe、设计压测、比较方案、定位 TTFT/TPOT/吞吐问题、复核报告或沉淀调优台账时使用。
---

# GPU Serving Tuner

把一次性的“改参数、跑压测”转化为可复现、可比较、可审计的工程闭环。

默认只读。未获得用户明确授权时，不启动或停止服务、不占用 GPU、不修改远端文件、不打补丁、不安装或编译依赖。

## 选择工作模式

先判断任务属于哪一种；可以组合，但要分别说明产物。

- **Capture**：只读采集实际运行态，生成部署快照。
- **Curate**：把散落脚本整理成最小 recipe，保留必要补丁与构建说明。
- **Benchmark**：固定负载与口径，建立基线或比较方案。
- **Tune**：按单变量或分层叠加方式探索参数。
- **Diagnose**：解释 TTFT、TPOT、吞吐、失败率或稳定性异常。
- **Review**：复核报告、表格和结论是否能回溯到原始证据。

## 开始前的证据门禁

不要从目录名、README 或脚本默认值猜测当前配置。尽量确认以下五类身份；缺失项写成 `unknown`，并说明它会限制什么结论。

1. **运行时身份**：镜像 digest、代码 revision、补丁集、框架及依赖版本。
2. **部署身份**：节点与 GPU 拓扑、角色划分、实际进程 argv、环境变量、挂载、端口。
3. **配置身份**：模型及其 revision、并行度、KV dtype、缓存、调度、传输和路由参数。
4. **负载身份**：数据集或生成规则、输入/输出长度、命中率、到达模型、并发或速率、时长、seed。
5. **验收身份**：指标定义、统计窗口、SLO、正确性门禁、失败判定、重复次数。

只读采集方法见 [references/capture-deploy.md](references/capture-deploy.md)。

## 核心闭环

1. **划定范围并保护现场**：确认可用 GPU、端口、容器名、结果目录和缓存目录；并行实验必须隔离这些资源。
2. **冻结基线**：保存运行时、部署、配置、负载和验收身份；先复现基线，再讨论优化。
3. **验证测量链**：执行最小 smoke；确认请求成功、输出正确、统计窗口有效、负载生成器能跟上。
4. **分类瓶颈**：先区分 TTFT、TPOT、容量/稳定性或正确性问题，再选择实验变量。
5. **设计最小实验**：优先单变量；若必须成组修改，明确写为 bundle，不能把收益归因给其中某一项。
6. **分层验证**：静态检查 → 启动 → 健康 → 生成 → 正确性 → 短测 → 边界复测 → 长稳态。
7. **做出决策**：只有通过正确性、SLO、keep-up 和稳定性门禁的点才进入性能比较。
8. **归档证据**：保存实际命令、配置、原始结果、提取表、分析和决策；结论必须能回链。

## 调优决策顺序

按以下顺序判断，避免用更高吞吐掩盖不可用结果：

1. 请求和输出是否正确；
2. 压测器是否按目标负载运行，服务是否 `keeps_up`；
3. SLO 和失败率是否通过；
4. 同口径下的吞吐、延迟、每卡效率或用户定义的成本指标；
5. 复杂度、可运维性、补丁维护成本和回滚难度。

过载点、无效点和失败点是诊断证据，不是性能冠军。模拟接受长度、fake P/D 等工具只能隔离变量，不能直接代表生产结论。

## 快速迭代方法

- 用短测筛掉明显差点并寻找 knee；用重复测试和长稳态确认边界。
- 水平变量用小规模 A/B/C；叠加优化时每次只增加一层。
- 高成本全矩阵只给已通过门禁的候选；探索臂继续跑低成本测试时必须物理和逻辑隔离。
- 任何跨天、跨机器或跨镜像比较，都先重新跑 anchor 点。
- 为每轮设置时间盒和退出条件：保留、放弃或待定，不让实验无限扩张。
- 记录缓存冷热、JIT 状态、邻近负载、功耗/频率策略和时钟，避免把环境漂移当收益。

详见 [references/rapid-iteration.md](references/rapid-iteration.md) 与 [references/tuning-playbook.md](references/tuning-playbook.md)。

## 启动脚本与 recipe

整理 recipe 时只保留复现启动所需内容：

- 每个引擎或来源使用独立目录，如 `sglang/`、`vllm/`、`ali_sglang/`；不存在可用脚本时不要创建空目录。
- 提供推荐入口和变体索引；历史方案保留原名，避免静默改变调用路径。
- 参数集中在 env/config；角色特有参数分别表达，不把 prefill/decode 强行合并。
- 复杂 launcher 必须能做不修改系统的 `render`/`plan`/`dry-run`，输出最终 argv、env、挂载、端口和资源占用。
- 启动前检查镜像、模型资产、GPU 所有权、端口和依赖；停止脚本按精确容器或 PID 操作，默认 dry-run。
- 优先使用上游支持的配置。补丁只保留来源、适用 revision、目的、apply/check 命令、构建要求和回滚方式。
- 不收录权重、wheel、二进制、JIT cache、大日志和原始结果。

详见 [references/script-and-recipe-design.md](references/script-and-recipe-design.md)。

## 测试与指标

每个可比较点应遵循同一流水线：

```text
preflight → optional flush → warmup → load → steady-window analysis → validity gate → archive
```

不能执行 flush 或 warmup 时，必须显式声明例外并记录原因；不能静默跳过。测试分层、复测策略和正确性门禁见 [references/testing-recipes.md](references/testing-recipes.md)。指标公式、稳态窗口和不确定性见 [references/metrics-and-trust.md](references/metrics-and-trust.md)。

## 台账与文档

推荐最小布局：

```text
launch/                 可复现启动脚本、配置和最小补丁说明
bench/                  负载定义与压测入口
results/<tag>/<run-id>/ 不可变的单次原始结果与元数据
analysis/iterations/    每轮假设、证据和决策
plans/                  阶段计划与验收条件
report/                 面向读者的结论和索引
history.md              只追加的时间线
```

同一模式内可以维护 `recommended` 指针；不同硬件、负载、SLO 或运行时之间不要宣称一个全局“best”。详细规范和模板见 [references/ledger-and-layout.md](references/ledger-and-layout.md) 与 `templates/`。

## 脱敏规则

提交或分享前必须扫描并替换：用户名、主机名、私网 IP、绝对路径、私有仓库/镜像、token、密钥、客户/项目/模型代号、内部价格、未公开性能数据。使用 `<node-a>`、`<engine-url>`、`<model-root>`、`<private-registry>/<image>@<digest>` 等占位符。

示例数据必须标注为 `synthetic`，只能展示结构和计算关系，不能伪装成真实结果。不要仅遮掉值而保留可反推身份的组合信息。详见 [references/documentation-and-sanitization.md](references/documentation-and-sanitization.md)。

## 完成标准

- [ ] 五类身份已记录，未知项及影响已说明。
- [ ] 基线可复现，最终命令来自实际 argv 或 launcher 的 render 输出。
- [ ] 所有比较点的负载、统计窗口、硬件与指标定义一致或已归一化。
- [ ] 正确性、keep-up、SLO 和稳定性门禁先于性能排名。
- [ ] 关键边界有重复或长稳态验证，结论包含不确定性。
- [ ] 每个结论可回链到不可变 run-id；失败实验也有记录。
- [ ] recipe 有 preflight、dry-run、精确清理和最小补丁说明。
- [ ] 文档与样例通过敏感信息扫描，示例均明确为合成数据。
- [ ] 变更经过 `make check`；未在用户确认前安装到环境。
