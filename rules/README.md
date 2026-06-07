# ai-harness-toolset repo-only rules tier

This folder is the **repo-only rules tier** — operating rules that apply to **developing the `ai-harness-toolset` repository itself**, collected here so the repo-development surface has a single home to migrate such rules into. It is **not** part of the global distribution (it is not under the `snippets/` payload root), so it is never installed to an adopter's `<ToolRoot>`.

## Two rules tiers — do not confuse them

- **Global-distribution rules:** `snippets/rules/*.md` — ship with the toolset (under the `snippets/` payload root) and apply to any project that adopts ai-harness. Self-contained, no `docs/` dependency.
- **Repo-only rules (this folder):** `<repo-root>/rules/*.md` — apply only to developing this repo. May reference the repo's own `docs/` (repo-internal). Pointed at from the root `CLAUDE.md` / `AGENTS.md`.

## What belongs here

- Reusable repo-development rules for this repo that are **not** absorbed into a skill, template, or script and are **not** adopter-universal (those go to `snippets/rules/`).
- **One rule-group concept per file.**

## Rules in this tier

- [powershell-and-file-encoding.md](powershell-and-file-encoding.md) — PowerShell `.ps1` encoding / line-ending discipline, native-executable output capture, and the `.md` / `.json` / `.txt` encoding convention for this repo.
