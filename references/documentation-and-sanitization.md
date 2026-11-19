# 文档整理与脱敏

## 证据链

文档之间保持以下方向：

```text
plan/hypothesis → config-id → run-id → raw result → extracted table → analysis → decision/report
```

报告中的每个数字应能定位到表格行和原始 run-id；无法核验的项明确标记，不用推测补齐。

## 文档层次

- **README**：入口、依赖、推荐用法和限制。
- **plan**：假设、变量、门禁、资源和退出条件。
- **iteration**：单轮变更、结果、解释和三态决策。
- **history**：只追加时间线，不承载长篇分析。
- **report**：面向读者的最终结论、适用边界和证据索引。
- **provenance**：来源路径、revision、复制/改写范围和许可证。

用索引和相对链接连接文档，避免复制同一结论到多个文件后产生漂移。

## 必须移除或替换的信息

- 真实用户名、邮箱、主机名、私网 IP、VPN/集群标识；
- 内部绝对路径、私有仓库、镜像 registry、对象存储 URI；
- token、密码、cookie、密钥、证书和带签名 URL；
- 客户、项目、模型代号及未公开合作方信息；
- 内部价格、营收目标、容量规划与未公开性能数据；
- 能通过组合反推身份的时间、拓扑和命名细节。

## 占位符约定

使用语义明确的占位符：

```text
<node-a>
<engine-url>
<model-root>/<model-revision>
<private-registry>/<image>@<digest>
<workspace>/results/<tag>/<run-id>
```

占位符不能被脚本当作可执行默认值；运行前必须由配置替换。

## 示例数据

样例第一处显著位置标注 `synthetic`。数值用于解释列、单位和计算，不复刻真实实验分布。若无法证明数据已公开或已授权，改为小型合成数据。

## 发布前扫描

至少检查：

- IPv4/IPv6、邮箱、用户名路径、绝对内部路径；
- `token`、`secret`、`password`、私钥头、云访问键模式；
- registry、主机别名、项目/客户/模型代号；
- 大文件、日志、结果、缓存、wheel、二进制和符号链接；
- Git 历史或 patch 中是否仍含敏感值。

自动扫描只能发现模式，最后还要做语义审阅。脱敏后重新检查命令和文档是否仍可读、占位符是否一致。
