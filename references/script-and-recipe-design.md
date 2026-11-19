# 启动脚本与 recipe 设计

## 目录按实现或来源分组

```text
launch/<engine-or-source>/
├── README.md
├── configs/
├── start.sh
├── stop.sh
├── status.sh
└── patches/          # 仅在必要时存在
```

例如 `sglang/`、`vllm/`、`ali_sglang/`。来源差异会影响镜像、参数和补丁责任，不能仅靠文件名后缀区分。没有经过验证的实现时，不创建空目录或暗示支持。

## 脚本职责

- `start.sh`：preflight 后精确启动，不负责压测。
- `stop.sh`：只停止本 recipe 创建的资源，默认 dry-run，显式 `--apply` 才执行。
- `status.sh`：只读展示容器/PID、端口、GPU 和健康状态。
- `bench/`：单独保存负载定义与压测入口。
- `README.md`：写清推荐入口、依赖、资源计划、验证与限制。

脚本长度不是硬指标；优先保持单一职责、直接 argv 和易读错误处理。公共逻辑明显重复时才抽取 library。

## 安全 shell 风格

```bash
#!/usr/bin/env bash
set -euo pipefail

cmd=(python3 -m engine.launch --model "$MODEL" --port "$PORT")
printf ' %q' "${cmd[@]}"
printf '\n'
exec "${cmd[@]}"
```

- 使用数组传递 argv，不使用 `eval` 或拼接 shell 字符串。
- 用户值和路径始终引用；env 文件用 shell-safe quoting 写入。
- 不把密码、token 或私有 URI打印到日志。
- 所有环境相关值通过必填变量或显式配置传入，不藏在脚本默认值中。
- 错误信息应说明缺少什么、如何修复。

## render / plan / dry-run

复杂 launcher 至少提供一种非修改模式，输出：

- 最终 argv 和环境变量名；
- 镜像、挂载和模型 revision；
- GPU、端口、容器名和缓存目录；
- 启动顺序、健康检查和停止目标。

输出可做静态审查，但最终部署快照仍应从实际运行进程采集。

## Preflight

启动前检查：

1. 镜像 digest 或本地产物存在；
2. 模型分片、tokenizer 和额外资产齐全；
3. GPU 未被未知任务占用；
4. 端口未占用；
5. 容器名/PID 文件不冲突；
6. 角色与设备映射有效；
7. 结果和缓存目录可写。

## 补丁最小包

补丁目录只保留：patch 文件、`README.md` 和必要构建命令。README 包含来源、适用 revision、目的、check/apply、构建、验证、回滚和已知风险。不要提交 wheel、镜像层、构建缓存或二进制。

## Recipe 验收

- shell 语法通过；
- dry-run 不产生容器、进程或文件修改；
- 最终 argv 可读且角色参数完整；
- start/stop/status 的资源标识一致；
- README 的示例全部脱敏；
- 历史入口未被无说明地删除或改义。
