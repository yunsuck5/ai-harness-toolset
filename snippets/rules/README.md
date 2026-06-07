# ai-harness-toolset global rules tier

This folder is the **global-distribution rules tier**. It ships with the toolset (it lives under the `snippets/` payload root, so it is installed to `<ToolRoot>/snippets/rules/` alongside the snippet, skills, and templates). It is the home for the reusable always-on operating rules that are **not absorbed into a skill, template, or script** — the cross-cutting invariants the always-loaded snippet bootstrap points to.

## Relationship to the snippet

The snippet (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) is the always-loaded **bootstrap** that the user adopts into a `CLAUDE.md` / `AGENTS.md` managed block. It carries only the critical safety floor inline and points here for the full operating rules — the same relationship a Claude Code `CLAUDE.md` has to its rules tier. These rule files are **not auto-loaded**; the snippet's **rule trigger gate** (an action-class → rule-file map in `## Operating rules and topology`) requires the agent to read the matched rule file (at `<ToolRoot>/snippets/rules/<name>.md`) *before* answering or acting on that area — not an optional "when it seems relevant" read.

## What belongs here

- Reusable, vendor-neutral, always-on operating rules that are **not** an intent-triggered procedure (those are skills), not an artifact shape (those are templates), and not deterministic behavior (those are scripts).
- Public-safe content only — no secrets, no machine/user-specific paths, no session/handoff state. No dependency on `docs/` (which is not part of the distribution).
- **One rule-group concept per file.**

## What does NOT belong here

- Repository-development-only rules for this repo itself — those go in the **repo-only** tier `<repo-root>/rules/` (not distributed).
- Anything that fits a skill / template / script — absorb it there instead.
- Rationale / design records / contracts — those stay in `docs/` (source-repo only), never referenced as a runtime dependency from a distributed file.

## Rules in this tier

- [global-file-mutation-boundary.md](global-file-mutation-boundary.md) — global / user instruction file mutation boundary and the managed-block adoption contract.
- [no-background-or-hidden-state.md](no-background-or-hidden-state.md) — no autonomous / hidden execution (no daemon / watcher / scheduler / hook / self-triggering task; explicit-prompt-only triggers), with supervised, read-only, output-isolated, fully-joined background / parallel work allowed; no sidecar state file; no per-user log partitioning or ownership metadata.
- [repository-change-safety.md](repository-change-safety.md) — commit / push need explicit approval; a verdict approves nothing; no automatic `.gitignore` mutation; temporary-file hygiene.
