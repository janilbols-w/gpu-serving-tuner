# 测试数据汇总表 schema 与 tag 规范

## 1. 列结构（72 列模板 + 扩展）

模板列（顺序固定）：
`客户端, 后端网路链接, 数据集, 输入长度(k), 输出长度(k), 并发数, 目标 TPM, 总请求数, 成功数, 失败数, 成功率,
Avg/Min/Max/P50/P90/P95/P99 TTFT(s), 同序 TPOT(s), Avg/P50/P90/P95/P99 TTLT(s),
Avg/P50/P90/P95/P99 Rate(t/s), Avg/P50/P90/P95/P99 ITL(s),
Avg Prompt/Completion Tokens, Total Tokens, Avg Cached Tokens, Avg Cache Hit Ratio, Avg Total Time(ms),
Output TPM, Output TPS, Input TPM, TPM, RPM, 节点数, 平均节点并发数,
Gate×10, Cache/Prefill/Decode Price, 单节点 TPM, 单节点 RPM, 月产值(万), 平均节点月产值(万), 单机成本(万), 成本覆盖`

扩展列（放在末尾，不破坏模板）：
`tag`（区分批次）、`报告表号`（PDF 来源）、`每卡总吞吐(t/s)`、`单机月收入(万)`、`备注`（口径/部署/注脚）

## 2. 单位

- 时间列**全部秒**（模板约定），`Avg Total Time(ms)` 为毫秒
- `TPM` = token/分钟；`TPM` 为整集群合计，`单节点 TPM` = ÷ 节点数
- `RPM` = 完成请求/分钟
- `Rate(t/s)` = 单请求输出速度 ≈ 平均输出 token ÷ 平均 TTLT

## 3. tag 规范

`<来源>-<方案>-<批次>`，例如：

| tag | 含义 |
|---|---|
| `REPORT-3P1D-48PT` | 报告 48 点矩阵 |
| `REPORT-3P1D-TABLE7` | 报告表 7 的四个 SLO 点 |
| `RETEST-20261111-FITOPT-6P1D` | 某次复测（带日期与方案） |
| `PDF-T5-AGENTX` | 从 PDF 表 5 录入 |
| `PDF-T6-PEAK` / `T7-SLO` / `T8-VALUE` / `T9-RATIO` / `T4-REF` | 其他报告表 |

规则：**同一批次 tag 不变**，新批次换时间戳；PDF 录入与原始数据分别打 tag，便于核对。

## 4. 留空规则

- 没有的分布（如 p95）→ 留空，不插值
- 定价口径不同（不同来源的目录价可能不同，例如模板用 0.04/2/8、报告用 8/2/28）→ 价格/月产值列留空，在 `备注` 说明
- 由 PDF 录入的行：TTFT/TPOT 用报告原值，`报告表号` 必填
