# ai-harness-toolset repo-only rules tier

This folder is the **repo-only rules tier** — operating rules that apply to **developing the `ai-harness-toolset` repository itself**, collected here so the repo-development surface has a single home to migrate such rules into. It is **not** part of the global distribution (it is not under the `snippets/` payload root), so it is never installed to an adopter's `<ToolRoot>`.

## Two rules tiers — do not confuse them

- **Global-distribution rules:** `snippets/rules/*.md` — ship with the toolset (under the `snippets/` payload root) and apply to any project that adopts ai-harness. Self-contained, no `docs/` dependency.
- **Repo-only rules (this folder):** `<repo-root>/rules/*.md` — apply only to developing this repo. May reference the repo's own `docs/` (repo-internal). Pointed at from the root `CLAUDE.md` / `AGENTS.md`.

## What belongs here

- Reusable repo-development rules for this repo that are **not** absorbed into a skill, template, or script and are **not** adopter-universal (those go to `snippets/rules/`).
- **One rule-group concept per file.**

## Rules in this tier

- [docs-working-model.md](docs-working-model/docs-working-model.md) — the docs working model (the `rules/docs-working-model/` rule package; this link routes to its operative home `docs-working-model.md`): document artifact classes (planning / Work Packet / operator report / active surface / future-work queue), the Design/Plan/Spec lifecycle + Spec identity (target state + durable boundary), end-state placement + transition, Spec↔implementation 1:1 synchronization + the proportionality rule, the durable-pointer prohibition, the on-demand status-briefing model, and the reduced two-level closeout gate. The package carries package-local `templates/` (Design/Plan/Spec) and `checklists/` (conformance + closeout + promotion-boundary / promoted-but-not-live), routed from the operative home (not from this index). Triggered before a docs change/placement/closeout by the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Source / docs` row). Self-contained — the predecessor rationale/record is preserved in git history; the placement orientation map remains `docs/README.md`.
- [powershell-and-file-encoding.md](powershell-and-file-encoding.md) — PowerShell `.ps1` encoding / line-ending discipline, native-executable output capture, and the `.md` / `.json` / `.txt` encoding convention for this repo.
- [rule-authority.md](rule-authority.md) — authority classification and disposition for repo-rule clauses; triggered only while authoring or revising a rule, or handling a higher-rule conflict.
- [terminology-glossary.md](terminology-glossary.md) — adopted / rejected project-term meaning의 최소 single home. 채택 의미를 확인할 때 read-only로 조회하고, 새 프로젝트 공용 용어 도입·채택 의미/분류 변경(더 이상 공용이 아니어서 제거하는 처분 포함)·관측된 이름 collision·rejected-term revival 위험이 있을 때만 용어 결정을 수정한다. meaning-preserving correction은 direct edit이며 ordinary use와 candidate-local label은 mutation trigger가 아니다.
