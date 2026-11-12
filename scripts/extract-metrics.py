#!/usr/bin/env python3
"""从 results/*/{analysis.json|raw.summary.json} 批量抽取指标为 CSV。
用法: extract-metrics.py <ROOT> <TAG> [--label-substr SUB] [--gpus N] [--nodes N]
输出列: tag,label,length_k,out_k,conc,rate,gpus,nodes,n_ok,n_fail,
        ttft_p50/p90/p99, tpot_p50/p90/p99(ms->s), e2e_p50/p90/p99,
        out_tok_s,prompt_tok_s,total_tok_s,cached_tok_s,completed_req_s,hit,accept
"""
import argparse, glob, json, os, csv, sys
ap=argparse.ArgumentParser()
ap.add_argument('root'); ap.add_argument('tag')
ap.add_argument('--label-substr', default='')
ap.add_argument('--gpus', type=int, default=32); ap.add_argument('--nodes', type=int, default=4)
a=ap.parse_args()
rows=[]
for f in sorted(glob.glob(os.path.join(a.root,'**','analysis.json'), recursive=True)
              + glob.glob(os.path.join(a.root,'**','raw.summary.json'), recursive=True)):
    d=os.path.dirname(f)
    if a.label_substr and a.label_substr not in d: continue
    try: p=json.load(open(f))
    except Exception: continue
    lat=(p.get('latency') or {}).get('steady') or (p.get('latency') or {}).get('all') or {}
    st=p.get('steady') or {}; tk=p.get('tokens') or {}; rq=p.get('requests') or {}; run=p.get('run') or {}
    t=lat.get('ttft_s') or {}; tp=lat.get('tpot_ms') or {}; e=lat.get('e2e_s') or {}
    ms=lambda d,k: (d.get(k)/1000.0 if isinstance(d.get(k),(int,float)) else '')
    rows.append(dict(tag=a.tag,label=run.get('label') or os.path.basename(d),rate=run.get('rate'),
      conc=run.get('concurrency'),gpus=a.gpus,nodes=a.nodes,n_ok=rq.get('ok'),n_fail=rq.get('failed'),
      ttft_p50=t.get('p50'),ttft_p90=t.get('p90'),ttft_p99=t.get('p99'),
      tpot_p50=ms(tp,'p50'),tpot_p90=ms(tp,'p90'),tpot_p99=ms(tp,'p99'),
      e2e_p50=e.get('p50'),e2e_p90=e.get('p90'),e2e_p99=e.get('p99'),
      out_tok_s=st.get('output_tok_s'),prompt_tok_s=st.get('prompt_tok_s'),total_tok_s=st.get('total_tok_s'),
      cached_tok_s=st.get('cached_tok_s'),completed_req_s=st.get('completed_req_s'),
      hit=tk.get('cached_fraction'),accept=((p.get('server_metrics') or {}).get('headline') or {}).get('spec_accept_length')))
if not rows: sys.exit('no analysis.json/raw.summary.json found')
w=csv.DictWriter(sys.stdout, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
