# ai-harness-toolset repo-only rules tier

This folder is the **repo-only rules tier** — operating rules that apply to **developing the `ai-harness-toolset` repository itself**, collected here so the repo-development surface has a single home to migrate such rules into. It is **not** part of the global distribution (it is not under the `snippets/` payload root), so it is never installed to an adopter's `<ToolRoot>`.

## Two rules tiers — do not confuse them

- **Global-distribution rules:** `snippets/rules/*.md` — ship with the toolset (under the `snippets/` payload root) and apply to any project that adopts ai-harness. Self-contained, no `docs/` dependency.
- **Repo-only rules (this folder):** `<repo-root>/rules/*.md` — apply only to developing this repo. May reference the repo's own `docs/` (repo-internal). Pointed at from the root `CLAUDE.md` / `AGENTS.md`.

## What belongs here

- Reusable repo-development rules for this repo that are **not** absorbed into a skill, template, or script and are **not** adopter-universal (those go to `snippets/rules/`).
- **One rule-group concept per file.**

## Rules in this tier

- [docs-working-model.md](docs-working-model/docs-working-model.md) — the docs working model (now the `rules/docs-working-model/` rule package; this link routes to its operative home `docs-working-model.md`): docs placement, top-down change flow, single-home-plus-pointers, per-system `STATUS.md` shape / altitude, `BACKLOG.md` closed-row tombstone, the durable-pointer prohibition, the on-demand status-briefing model, the two-level closeout reconciliation gate, and the Design/Plan/Spec lifecycle. The package now also carries package-local `templates/` (Design/Plan/Spec) and `checklists/` (Design/Plan/Spec conformance + closeout), routed from the operative home (not from this index). Triggered before a docs change/placement/closeout by the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Source / docs` row). Rationale/record: `docs/policies/DOCS_OPERATING_MODEL.md` (change/closeout) + `docs/README.md` (placement map).
- [powershell-and-file-encoding.md](powershell-and-file-encoding.md) — PowerShell `.ps1` encoding / line-ending discipline, native-executable output capture, and the `.md` / `.json` / `.txt` encoding convention for this repo.
- [terminology-glossary.md](terminology-glossary.md) — project terminology glossary: the single home of project term meaning (do-not-repeat). A flat repo-only rule sibling of `powershell-and-file-encoding.md` (not part of the `docs-working-model` package). Route-only here — the term entries themselves are not duplicated into this index. Triggered before docs / spec / review / brief / planning work where project-specific terms appear, by the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Project terminology` row).
