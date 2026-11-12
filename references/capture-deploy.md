# 只读盘点清单（部署参数）

目标：**不改动服务**的前提下，拿到"这套服务到底怎么配的"的一手证据。所有命令只读。

## 1. 找服务

```bash
# 每台节点列出与推理相关的容器（排除历史/无关容器）
docker ps --format '{{.Names}}|{{.Image}}|{{.Status}}' | grep -E 'sglang|vllm|dynamo|trtllm|glm'
# 看拓扑：哪些机器有 P、哪些有 D、路由/etcd/NATS 在哪
```

注意区分两类部署：
- `docker run ... python3 -m sglang.launch_server`：参数在容器 `Config.Cmd` 里
- `--entrypoint bash ... sleep infinity`：容器只是壳，**真正参数要看容器内进程**

## 2. 拿引擎真实参数

```bash
# 容器壳场景：进容器抓进程
pid=$(docker exec <c> pgrep -f 'dynamo.sglang|sglang.launch_server' | head -1)
docker exec <c> sh -c "tr '\0' '\n' < /proc/$pid/cmdline"   # 完整 argv（含空格参数）
docker exec <c> sh -c "tr '\0' '\n' < /proc/$pid/environ"   # 环境变量（engine_env 的也在）
```

必看字段：
`--tp-size / --dp-size / --ep-size / --attn-cp-size / --pipeline-parallel-size`、
`--chunked-prefill-size / --max-running-requests / --mem-fraction-static`、
`--kv-cache-dtype / --page-size`、`--disaggregation-transfer-backend`、
`--enable-hierarchical-cache`（及 hicache-size/io/write-policy）、
`--cuda-graph-*`、`--speculative-*`、`--moe-runner/a2a-backend`、`--router-mode`。

## 3. 校验 KV 与模型

```bash
# kv dtype 以启动日志 server_args 为准（auto 可能是 bf16，不是 fp8）
grep -m1 -oE "'kv_cache_dtype': '[^']*'" <容器日志>
grep -m1 -oE "'page_size': [0-9]+" <容器日志>
# 模型路径：容器内 /model 对应的宿主目录
docker inspect <c> --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
# 代码版本：挂载的 sglang-src commit 或镜像 tag + SOURCE.txt
```

## 4. 网络与 rail

```bash
# 每卡对应的 HCA（与 --disaggregation-ib-device 必须一致）
cat /sys/class/infiniband/mlx5_*/ports/1/state
ip -4 -o addr show | grep -v 127.0.0.1        # 管理网/数据网
```

## 5. 路由与前置服务

- smg：`/pylib/bin/smg launch --pd-disaggregation --prefill <url> <bootstrap> …`
- Dynamo：etcd/NATS/frontend 三件套 + `--router-mode round-robin|kv`
- 记录：端口、策略、健康检查阈值、超时、max-payload

## 6. 产出（deploy-<方案>/）

```
README.md          拓扑表 + 参数表 + 与基线差异表 + 起停方式
launch-record/     现场 .cmd 原文（逐字节，不要手抄）
scripts/           按节点/角色的启动脚本（从 .cmd 生成）+ up/status/down
inventory/         topology.md（端口/rail/容器矩阵）、config-diff-<baseline>.md
```

三条纪律：
1. 参数不从"文档"抄，从**现场命令与进程**取；文档与脚本冲突时以脚本为准。
2. 生成启动脚本时用程序从 `.cmd` 转写，避免手抄错引号/空格。
3. 采集后复查容器 `Status` 与启动时间未变，证明只读。
