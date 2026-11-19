# 结果表 schema

不要从一开始固化超宽表。先维护一组稳定的核心列，额外框架指标放入扩展表或 JSON。

## 核心列

| 列 | 含义 |
|---|---|
| `run_id` | 唯一且不可变的运行 ID |
| `tag` | 脱敏实验组名称 |
| `status` | `valid` / `invalid` / `failed` |
| `invalid_reason` | 无效原因；有效时留空 |
| `config_id` | 部署与参数身份 |
| `runtime_id` | 镜像/代码/补丁身份 |
| `workload_id` | 数据、长度、命中与生成器身份 |
| `started_at` | 带时区时间 |
| `duration_s` | 稳态窗口秒数 |
| `requests` | 稳态样本数 |
| `success_rate` | 成功请求比例 |
| `keeps_up` | 负载有效性布尔值 |
| `ttft_p50_ms` / `ttft_p99_ms` | TTFT 分位数 |
| `tpot_p50_ms` / `tpot_p90_ms` | TPOT 分位数 |
| `input_tok_s` / `output_tok_s` | 稳态吞吐 |
| `gpu_count` | 实际参与 GPU 数 |
| `slo_pass` / `correctness_pass` | 门禁结果 |
| `source_path` | 原始结果相对路径 |
| `notes` | 简短说明，不放敏感信息 |

## 规则

- 单位写入列名或 schema，不靠读者猜测。
- 未采集填空，不填 `0`；不适用可填 `n/a`，并在解析层区分。
- 派生指标保存公式版本；重新计算时保留旧表或版本号。
- 所有百分位必须关联样本数和统计窗口。
- 不同负载、运行时或 SLO 的行可以共表，但报告中必须分组，不能直接全局排名。

`examples/table-schema.example.csv` 是明确标记的合成数据，仅用于展示结构。
