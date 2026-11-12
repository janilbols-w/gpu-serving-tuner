# <方案名> 部署

> 快照：YYYY-MM-DD HH:MM，<运行中/已下线>；采集方式：只读。

## 1. 拓扑

| 角色 | 节点 | IP | 容器 | GPU | HTTP / bootstrap |
|---|---|---|---|---|---|

## 2. 参数

| 项 | P | D | 说明 |
|---|---|---|---|

## 3. 与上一版差异

| 维度 | 上一版 | 本版 |
|---|---|---|

## 4. 起停

```bash
bash scripts/up.sh        # P → 等健康 → D → 等健康 → router
bash scripts/status.sh    # 只读
bash scripts/down.sh --yes
```

## 5. 注意

- <模型路径差异 / 端口冲突 / 缓存冷热 / 重启策略缺失 等>
