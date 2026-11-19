# 分层测试配方

## 固定流水线

```text
preflight → flush or declared exception → warmup → load → analyze → validity gate → archive
```

脚本不得在缺少 flush 或 warmup 工具时静默继续。若系统不支持对应阶段，使用显式开关并把例外原因写入 metadata。

## 测试层级

### 1. 静态与 dry-run

检查 shell/Python 语法、最终 argv、镜像/模型/端口/GPU 计划、结果目录和停止目标。此阶段不启动服务。

### 2. Smoke

最小负载确认健康接口、真实生成、输出格式和基本正确性。P/D 系统需要额外确认真实角色数据路径，不以注册成功代替。

### 3. Correctness gate

根据变更风险选择固定小集合、任务评测、长上下文检索、确定性 token 对比或数值误差检查。量化、缓存、通信和投机变更必须重新通过正确性门禁。

### 4. Anchor

固定一个代表性负载点，在每天、每台机器、每个镜像或每次重大变更开始时运行。anchor 漂移超过当前噪声预算时暂停比较。

### 5. Short sweep

沿一个变量逐档测试，寻找明显劣化点和 knee。短测结果只用于筛选。

### 6. Boundary confirmation

对候选点及其上下相邻档位重复测试；检查 SLO、keep-up、错误率和结果重叠程度。

### 7. Long steady-state

验证热状态、长尾、内存增长、缓存变化、重试和角色失衡。持续时间由系统周期和风险决定，不固化成通用分钟数。

### 8. Expanded matrix

只对晋级候选扩展输入/输出长度、命中率、并发/速率、采样或多轮场景。矩阵维度与生产工作负载假设对应。

## 重跑策略

- 配置或代码变化：重跑 correctness + anchor。
- 环境、镜像、机器或日期变化：重跑 anchor。
- 边界点：重复 seed 或运行顺序交错，降低系统漂移偏差。
- 可疑异常：先完整保存失败现场，再决定是否重跑；不覆盖原 run-id。

## 结果目录

每次运行写入 `results/<tag>/<run-id>/`，至少包含 metadata、实际命令、stdout/stderr、原始结果、分析结果和状态。run-id 应唯一且不可变。
