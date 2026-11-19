# <recipe name>

## Scope

- Engine/source: `<engine-or-source>`
- Supported roles: `<router/prefill/decode/combined>`
- Runtime identity: `<image-digest-or-revision>`
- Model identity: `<model-revision>`
- Status: `<exploratory/candidate/recommended/deprecated>`

## Resource plan

| Role | GPU allocation | Ports | Container/process prefix |
|---|---|---|---|
| `<role>` | `<gpu-set>` | `<port-set>` | `<prefix>` |

## Entry points

```bash
bash status.sh
bash start.sh --dry-run
bash start.sh --apply
bash stop.sh --dry-run
```

## Required configuration

List required env/config values. Use placeholders such as `<model-root>` and `<private-registry>/<image>@<digest>`; do not provide executable environment-specific defaults.

## Preflight and acceptance

- [ ] Image/build and model assets verified
- [ ] GPU and port ownership verified
- [ ] Final argv reviewed
- [ ] Health and registration passed
- [ ] Real generation passed
- [ ] Role data path passed where applicable
- [ ] Correctness gate passed
- [ ] Anchor benchmark recorded

## Patch/build provenance

Link to the minimal patch README, applicable revision, build identity and rollback instructions. Write `none` when no patch is required.

## Known limits

State untested modes, required exceptions and operational risks.
