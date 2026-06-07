# Rule: Global / user instruction file mutation boundary

Applies to any global or user-level AI instruction file: `%USERPROFILE%\.claude\CLAUDE.md` (Claude user-global), `<ProjectRoot>/CLAUDE.md` (Claude project-root), `%USERPROFILE%\.codex\AGENTS.md` or `%CODEX_HOME%\AGENTS.md` (Codex user-global), `AGENTS.override.md` at the Codex user-global scope (it takes precedence over `AGENTS.md` when both exist), and `<ProjectRoot>/AGENTS.md` (Codex project-root).

## No implicit or whole-file mutation

- Never implicitly, automatically, or whole-file overwrite any of the files above. The only governed way to write one is an **explicit, user-approved** replacement of the content **inside** the `AI_HARNESS_TOOLSET_GLOBAL` managed block; content outside the block — the user's own and project-specific instructions — is preserved verbatim.
- No global / user instruction file is auto-created. Inserting the managed block into an existing file that has no marker, and creating a missing destination file, are each a **separate** explicit-approval boundary, distinct from replacing an existing block.
- `%USERPROFILE%\.claude\AGENTS.md` is **never** a valid destination and must never be created — it is not a recognized global instruction path for any agent. No file is auto-created under `~/.claude/` or `~/.codex/`.

## Managed-block adoption contract

- The payload lives only between `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`. Replacing the block content is the standard adoption / update path.
- Markers are matched by **whole-line trim outside fenced code blocks**, so prose, inline-code, or fenced mentions of the marker text do not count as markers.
- A missing, incomplete (BEGIN/END count mismatch), duplicated, malformed (END before BEGIN, or an unbalanced fence), or nested marker pair is a **fail-fast / manual-review** condition: stop and do not edit the file.
- Destination-state branches: file absent → propose creation (separate approval); file present with 0 marker pairs → propose insertion point (separate approval); exactly 1 marker pair → show the diff, then replace the block content on approval; any malformed/ambiguous state → fail-fast, report, do not edit.

## Deterministic enforcement (distributed)

- The contract above is mechanically enforced by `scripts/apply-managed-block.ps1` + `scripts/lib/managed-block.ps1`: BOM refusal, invalid-UTF-8 / U+FFFD refusal, byte-exact preservation of content outside the block, fail-fast on ambiguous markers, and backup/rollback so a failed apply never leaves the target mutated.

## Project layer does not weaken this

A project-local instruction file may strengthen these boundaries but must not redefine, weaken, or bypass them without separate scoped approval.
