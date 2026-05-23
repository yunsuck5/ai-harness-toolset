# Legacy Knowledge Transfer

> Historical reference. This records the v0.x → v1 migration boundary and is not the source-of-truth for current tool behavior. For active behavior, use `README.md` and the active operational docs under `docs/`.

| legacy source | migration type | v1 destination | note |
|---|---|---|---|
| `.gitattributes` | KEEP with minor extension | `.gitattributes` | line endings |
| `CLAUDE.md` PowerShell rules | rewrite concept | `docs/policies/POWERSHELL_POLICY.md`, snippets | no root copy |
| `ai/scripts/lib/encoding.ps1` | rewrite concept | `scripts/lib/encoding.ps1` | helper names preserved where useful |
| `ai/scripts/lib/verify-ps1.ps1` | rewrite concept | `scripts/verify-ps1.ps1` | BOM + parser check |
| `ai/config/reviewer.json` | KEEP concept | `config/reviewer.json` | model/effort externalized |
| `run-codex-review.ps1` | REVIEW later | docs only | no wrapper in seed |
| `codex-review-schema.json` | REVIEW later | not first seed | result schema later |
| root `codex-review-input.md` | DROP | none | root singleton forbidden |
| install/rollback scripts | DROP | none | MVP non-goal |
