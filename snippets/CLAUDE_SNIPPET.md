<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
# ai-harness-toolset instructions for CLAUDE.md-compatible agents

This is a manually adopted ai-harness-toolset bootstrap for Claude Code and other CLAUDE.md-compatible agents. The user copied it into a `CLAUDE.md` inside the managed block delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`; only that block is ai-harness-owned. It is the always-loaded **bootstrap** layer: it carries the critical safety floor inline and points to the distributed rules tier for the full operating rules. It loads regardless of the agent's role (operator / reviewer / auditor / supervisor); role-specific behavior is set by `/goal`, the review input, or a skill, never assumed here. Review and Brief capabilities are on-demand skills the agent discovers via each skill's own `description` — this bootstrap neither indexes nor routes to them.

## Safety floor

- **Managed-block only.** Never implicitly or whole-file overwrite a global / user instruction file; edit only inside the marker pair and preserve everything outside it verbatim. A missing / incomplete / duplicated / malformed marker pair is a stop-and-manual-review condition, not an edit.
- **Explicit approval gates.** Adopting / updating this payload, committing, pushing, and any other global / user file mutation each require explicit user approval; a review verdict (`yes` / `no` / `yes with risk`) approves none of them.
- **Destination.** Claude: `<ProjectRoot>/CLAUDE.md` or `%USERPROFILE%\.claude\CLAUDE.md`. (Codex destinations are in `AGENTS_SNIPPET.md`.) `%USERPROFILE%\.claude\AGENTS.md` is never a destination and must never be created; no file is auto-created under `~/.claude/` or `~/.codex/`.

## Operating rules and topology

- **Operating rules tier.** The full operating rules ship with the toolset (not in `docs/`) at `<ToolRoot>/snippets/rules/*.md`, one rule group per file — `global-file-mutation-boundary.md`, `no-background-or-hidden-state.md`, `repository-change-safety.md`. Read the relevant file when its area applies.
- **Topology.** `<ToolRoot>` holds the installed `config` / `scripts` / `templates` / `snippets`, resolved in channel order: `-ToolRoot` → `AI_HARNESS_TOOL_ROOT` → `%USERPROFILE%\.claude\ai-harness-toolset\current` → `<ProjectRoot>/.ai-harness/` → stop. `<ProjectRoot>` is the target repo; all runtime artifacts go under `<ProjectRoot>/log/` (`log/review/`, `log/evidence/`, `log/chatlog/`, `log/brief/`).
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
