# AGENTS.md — ai-harness-toolset repo-local instructions (Codex)

Repo-local development instructions for working on the **ai-harness-toolset** repository itself, loaded by Codex from the repo root. This file is **not** the global managed-block snippet payload (`snippets/AGENTS_SNIPPET.md`) and does **not** embed it — adopter-universal ai-harness invariants are delivered by the global managed block instead (see the shared body). It is **public-safe and tracked**. Everything from the shared-body marker down is byte-identical to `CLAUDE.md`; only this header differs.

<!-- BEGIN SHARED BODY — byte-identical across CLAUDE.md and AGENTS.md; edit both together (see "Mirror-edit rule"). The header above is the only sanctioned per-tool divergence. -->

## What this file is

These are **repo-development** instructions for the `ai-harness-toolset` repo itself — a thin *docs trigger map* plus repo conventions and boundaries. They are **additive** to the global ai-harness instruction payload, not a copy of it:

- **Adopter-universal ai-harness invariants** (managed-block adoption discipline, hard boundaries, verdict vocabulary, ToolRoot/ProjectRoot topology, role/reviewer-mode) are delivered by the **global managed block** an operator adopts into their `%USERPROFILE%\.claude\CLAUDE.md` / Codex user-global `AGENTS.md` (source: `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`). This file does **not** restate them and does **not** embed that block.
- **Source-of-truth** for any subsystem lives in `docs/**` and `docs/contracts/**`; this file only says **when to read which doc**, never duplicating doc bodies. Start question→authority routing at `docs/current/SOURCE_OF_TRUTH.md`; placement at `docs/README.md`.
- **Skill discovery** (review / Brief workflows) is owned by each skill's own `description` (`snippets/claude-skills/ai-harness-review`, `snippets/claude-skills/ai-harness-brief`); this file is **not** a skill index, routing table, or trigger fallback.

## Docs trigger map

For each task class: *inspect first → validation/review gate → mutation boundary.* Pointers only — read the named doc for detail.

| Task class | Inspect first (source-of-truth) | Validation / review gate | Mutation boundary |
|---|---|---|---|
| **Review** subsystem | `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`; `snippets/claude-skills/ai-harness-review/SKILL.md`; `docs/systems/review/STATUS.md` (if status changes) | Codex local-correctness + system-coherence; `review-verify -RequireResult` | review machinery is maintenance-mode; a verdict approves no commit/push |
| **Install / update / uninstall** | `INSTALL.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (+ §8A activation surface); `docs/systems/install-update/STATUS.md` | relevant Pester lifecycle suites; `scripts/verify-ps1.ps1` | LTS; no global/user filesystem mutation without explicit approval |
| **Snippet** (global payload) | `docs/architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md` + `GLOBAL_SNIPPET_RELOCATION_AUDIT.md`; `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` + `STATUS.md` | full Pester (`Invoke-Pester -Path .\tests`); Codex review | classify every retained sentence by the single-home test; **no** skill-routing pointers; keep CLAUDE/AGENTS snippet symmetry |
| **Brief** | `docs/contracts/brief/BRIEF_CONTRACT.md`; `snippets/claude-skills/ai-harness-brief/SKILL.md` | Codex review | do not change `brief-*.ps1` unless explicitly scoped |
| **Source / docs** | `docs/README.md` (placement); `docs/current/SOURCE_OF_TRUTH.md` (routing); `docs/policies/DOCS_OPERATING_MODEL.md` (flow + two-level closeout gate) | Codex review on the **corrected** working tree | a source/doc edit **after** a review makes that review stale — re-run |
| **PowerShell / script** | `docs/policies/POWERSHELL_POLICY.md`; `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` | affected Pester + full suite; `scripts/verify-ps1.ps1` | see *Repo execution conventions* below; controlled IO via `scripts/lib/encoding.ps1` |
| **Repo-local instruction surface** (editing `CLAUDE.md` / `AGENTS.md`) | `docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`; `docs/architecture/instruction-surface/GLOBAL_SNIPPET_RELOCATION_AUDIT.md` | Codex review; `tests/repo-local-instruction-parity.Tests.ps1` | edit the shared body of **both** files symmetrically (*Mirror-edit rule*); tracked = public-safe only |

## Repo execution conventions

Always-on for this repo (its canonical scripts are all `.ps1` — `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 1). **Authority: `docs/policies/POWERSHELL_POLICY.md`** — the two rules below are concise pointers, not a restatement:

- **`.ps1` files must be UTF-8 with BOM + CRLF** (`POWERSHELL_POLICY.md` *Encoding and line endings*). Run `scripts/verify-ps1.ps1` after creating or modifying any `.ps1`.
- **Native-exe output must keep stdout / stderr / exit code separate** — no `2>&1` / `Out-String` / `Out-Null` merged capture for correctness checks; under Windows PowerShell 5.1 with `$ErrorActionPreference = 'Stop'` a merged capture aborts before `$LASTEXITCODE` can be read (`POWERSHELL_POLICY.md` *Native command invocation under `$ErrorActionPreference = 'Stop'`*).
- Other artifacts: `.md` / `.json` / `.txt` = UTF-8 **without** BOM + LF; controlled file IO uses `scripts/lib/encoding.ps1`.

## Public-safe boundary

These files are **tracked** (public to any contributor), so they carry only public-safe repo guidance. **Never** put in them: secrets / tokens / credentials; personal or machine-specific paths or state; local model endpoints; session-restore state or `log/brief/BRIEF.md` contents; private handoff or user decision history; runtime evidence or `log/**` payloads. Durable pointers resolve only to git-tracked files or git history — never to `log/**`, `polishing/**`, or user/global files (`docs/policies/DOCS_OPERATING_MODEL.md` §4).

## Mirror-edit rule

`CLAUDE.md` and `AGENTS.md` share the body below the marker **byte-for-byte**; only the per-tool header above differs. **Any edit to the shared body must be applied to both files in the same change** — a single-file shared-body edit is an **asymmetry defect** (the same discipline the global snippets follow, `docs/architecture/instruction-surface/GLOBAL_SNIPPET_RELOCATION_AUDIT.md` §2). The parity check `tests/repo-local-instruction-parity.Tests.ps1` guards this.

## Non-goals (this repo-local surface)

- No `.claude/*` or `.codex/*` instruction surface — root files are the sole surfaces (`docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` §5).
- No `/init` (Claude or Codex) — these files are authored, not scaffolded.
- No hooks, no Codex Rules, no daemon / watcher / scheduler.
- **Memory is not a delivery surface** — nothing here depends on memory; all of it is tracked.
- No ToolRoot move (vendor-neutral ToolRoot is a separate decision surface — `docs/architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md` §13).
- This file does **not** edit the global snippets. The two PowerShell rules now live **only here** (the repo-local root files): **Track D removed them** from the global snippet `## Other rules`, completing the Track C→D handoff (`docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` §9; `docs/systems/skills/STATUS.md` SK-03). No Batch 3 / Batch 4 implementation here.

<!-- END SHARED BODY -->
