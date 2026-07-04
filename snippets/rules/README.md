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

## Admission test for mixed content

When content bound for a rule file in this tier mixes adopter-universal and source-repository-specific material, the split is judged against this tier's own conditions above — the **universal core** (what may ship in a distributed rule) versus **project-residue** (what must stay in the rule's source repository). The primary test: **could an adopter who knows nothing about the rule's source repository read and follow the rule?** Content is kept out of the distributed rule when it:

- (a) violates the vendor-neutral condition above by requiring a specific vendor tool as a **compliance requirement**. Naming a *supported target surface* (e.g. a vendor instruction-file path this toolset manages) is not such a binding, and a generic example explicitly marked as such is allowed. Vendor-bound content is rewritten vendor-neutrally or kept out.
- (b) binds the rule to the source repository's own validation procedure — its review gates, check scripts, or test suite — as a compliance step.
- (c) depends on the source repository's governance (its candidate / planning lifecycle, its planning folders, its glossary).
- (d) carries measurement or pilot traces — those stay in the rule's source repository, never in a distributed rule.

Project-residue is re-homed to a source-repo-side surface (for this repository: the repo-only rules tier or another repo-side operating surface) or explicitly discarded with recorded rationale — never silently dropped, and never carried into the distributed rule. Content that *passes* the test still routes by form, per *What belongs here*: only an always-on operating rule lands in this tier — an intent-triggered procedure is a skill, an artifact shape a template, deterministic behavior a script.

## Reference direction across the distribution boundary

A distributed rule never depends on its source repository's surfaces (`rules/`, `rule_docs/`, `docs/`, the repo glossary) as a meaning source — consistent with the self-contained / no-`docs/`-dependency conditions above, its terms are defined in its own text or in surfaces shipped in the same distribution. (An orientation note that *routes content away* — like this README's own "repo-development-only rules go to the repo-only tier" line — is not such a dependency.) Repo-side surfaces may reference distributed rules (the installed payload is assumed). A distributed rule names another rule or capability only when it ships in the same distribution — and then interface, not semantics.

## Rules in this tier

- [global-file-mutation-boundary.md](global-file-mutation-boundary.md) — global / user instruction file mutation boundary and the managed-block adoption contract.
- [no-background-or-hidden-state.md](no-background-or-hidden-state.md) — no autonomous / hidden execution (no daemon / watcher / scheduler / hook / self-triggering task; explicit-prompt-only triggers), with supervised, read-only, output-isolated, fully-joined background / parallel work allowed; no sidecar state file; no per-user log partitioning or ownership metadata.
- [repository-change-safety.md](repository-change-safety.md) — commit / push need explicit approval; a verdict approves nothing; no automatic `.gitignore` mutation; temporary-file hygiene.
