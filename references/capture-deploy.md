# 只读部署盘点

目标是记录“实际运行了什么”，不是转述配置文件声称要运行什么。

## 采集顺序

1. **资源边界**：节点、GPU 型号与数量、GPU/NUMA/NIC 拓扑、功耗与频率策略。
2. **容器或进程身份**：镜像 digest、容器 ID、进程 PID、启动时间、代码 revision。
3. **实际 argv**：读取服务进程 cmdline。容器入口可能只是 supervisor 或 `sleep`，不能代替引擎 argv。
4. **实际环境**：读取进程环境。由启动脚本 source 的变量可能不在容器声明环境里。
5. **挂载与资产**：模型、配置、缓存、IPC、网络设备和日志挂载；记录 revision 或校验值，不复制敏感资产。
6. **运行时解析结果**：从启动日志或管理接口确认最终 server args、KV dtype、并行度、缓存和传输后端。
7. **服务拓扑**：router、prefill、decode、scheduler 等角色及其注册关系、端口和设备映射。

## 快照文件建议

```text
deploy-snapshot/
├── README.md
├── runtime.env.redacted
├── process.argv.txt
├── image.txt
├── mounts.redacted.txt
├── topology.md
└── provenance.md
```

`process.argv.txt` 应保存无 shell 重解释的参数序列；敏感值使用占位符，并在本地私有映射表中保留对应关系。不要把 token、密钥或完整私有 URI 写入快照。

## 快照与修改分离

Capture 模式不得顺手改配置。若发现问题：

- 在快照中记录观察事实；
- 在分析中写建议；
- 等用户明确授权后，另开变更步骤；
- 修改后生成新的快照和 run-id，不覆盖旧证据。

## 完整性检查

- README、argv、env、镜像、模型 revision 是否互相一致；
- 角色数量与 GPU 分配是否一致；
- 配置文件参数是否真的出现在最终 argv 或解析日志；
- 路由健康是否只代表注册成功，而非真实 P→D 数据路径成功；
- 所有时间戳是否使用同一时区或带时区信息。

## 脱敏示例

```text
image=<private-registry>/<engine>@sha256:<digest>
model=<model-root>/<model-revision>
prefill_endpoint=http://<node-a>:<port>
```

示例只表达结构；不得保留可反推组织、客户或项目身份的信息。
