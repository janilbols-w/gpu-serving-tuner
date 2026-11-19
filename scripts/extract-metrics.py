#!/usr/bin/env python3
"""Extract a compact, auditable CSV from benchmark analysis JSON files."""

import argparse
import csv
import json
from pathlib import Path
import sys


def percentile(metric, name):
    value = metric.get(name)
    return value if isinstance(value, (int, float)) else ""


parser = argparse.ArgumentParser()
parser.add_argument("root", type=Path)
parser.add_argument("tag")
parser.add_argument("--label-substr", default="")
parser.add_argument("--gpus", type=int)
args = parser.parse_args()

files = sorted(set(args.root.rglob("analysis.json")) | set(args.root.rglob("raw.summary.json")))
rows = []
for path in files:
    if args.label_substr and args.label_substr not in str(path.parent):
        continue
    try:
        with path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        print(f"skip {path}: {error}", file=sys.stderr)
        continue

    latency = payload.get("latency") or {}
    latency = latency.get("steady") or latency.get("all") or {}
    steady = payload.get("steady") or {}
    requests = payload.get("requests") or {}
    run = payload.get("run") or {}
    ttft = latency.get("ttft_s") or {}
    tpot = latency.get("tpot_ms") or {}

    rows.append({
        "run_id": run.get("run_id") or path.parent.name,
        "tag": args.tag,
        "label": run.get("label") or "",
        "rate": run.get("rate") or "",
        "concurrency": run.get("concurrency") or "",
        "duration_s": steady.get("duration_s") or "",
        "requests_ok": requests.get("ok") or "",
        "requests_failed": requests.get("failed") or "",
        "ttft_p50_ms": percentile(ttft, "p50") * 1000 if percentile(ttft, "p50") != "" else "",
        "ttft_p99_ms": percentile(ttft, "p99") * 1000 if percentile(ttft, "p99") != "" else "",
        "tpot_p50_ms": percentile(tpot, "p50"),
        "tpot_p90_ms": percentile(tpot, "p90"),
        "input_tok_s": steady.get("prompt_tok_s") or "",
        "output_tok_s": steady.get("output_tok_s") or "",
        "gpu_count": args.gpus if args.gpus is not None else "",
        "source_path": str(path.relative_to(args.root)),
    })

if not rows:
    parser.error("no readable analysis.json or raw.summary.json found")

writer = csv.DictWriter(sys.stdout, fieldnames=list(rows[0]))
writer.writeheader()
writer.writerows(rows)
