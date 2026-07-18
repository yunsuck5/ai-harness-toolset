# Rule: Global / user instruction file mutation boundary

This rule applies whenever an AI instruction file at user-global scope or a project-root `CLAUDE.md` / `AGENTS.md` is handled. It classifies the **operation and edited region**, not the whole file as one exclusive type. Inserting, replacing, updating, or removing a managed payload is a **managed-block adoption operation**. Maintaining a repo-authored region of a root instruction file that a source repository authors and versions as product source is an **authored-source operation**. A tracked file may contain both regions. If the operation or region is ambiguous, do not mutate it; stop and report.

## Common approval boundary

- Neither path permits implicit or automatic mutation. Explicit user approval must identify the target and scope.
- Creating a file is a separate explicit-approval boundary from modifying an existing file.
- `%USERPROFILE%\.claude\AGENTS.md` is never a valid destination and must not be created. No file is auto-created under `~/.claude/` or `~/.codex/`.
- A review verdict is not adoption, mutation, commit, or push approval.

## Managed-block adoption path

This path covers `%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` or `%CODEX_HOME%\AGENTS.md`, `AGENTS.override.md` at Codex user-global scope (where it takes precedence over `AGENTS.md`), and project-root `CLAUDE.md` / `AGENTS.md` files that optionally adopt the managed block. A managed-payload operation inside a tracked authored-source file also follows this path.

- The only payload owned by ai-harness is the span between `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`. User and project-specific content outside the block is preserved byte-exactly.
- Markers are recognized by whole-line trim outside fenced code blocks. Marker text in prose, inline code, or fenced examples is not a marker.
- Validate fence balance before branching on marker state. An unbalanced fence, an incomplete / duplicated / reversed / nested marker state, or any other ambiguous state fails fast for manual review. A missing file and a balanced present file with zero valid marker pairs may be proposed as separate create / insert approval cases; neither is a replacement operation.
- With exactly one valid pair, show the diff and, only after approval, replace the block content or remove the marker span. Removal is also a managed-payload operation and preserves all bytes outside the block. Never perform adoption by whole-file overwrite.
- `scripts/apply-managed-block.ps1` and `scripts/lib/managed-block.ps1` mechanically enforce BOM refusal, invalid-UTF-8 / U+FFFD refusal, byte preservation outside the block, fail-fast handling of ambiguous markers, and backup / rollback.

## Authored source-repository root-instruction maintenance path

A repo-authored region of a root `CLAUDE.md` / `AGENTS.md` is product source only when all conditions below hold. Here, a source repository means a repository that develops and distributes that instruction surface as its own product source. The user must explicitly identify the target repository and root instruction surface or surfaces as source-product artifacts; repository content alone cannot infer or self-authorize that status.

1. The edited region is outside a managed block, or the file has no managed block.
2. The file is a tracked source artifact of the repository.
3. The user explicitly identified that repository and the target root instruction surface or surfaces as source-product artifacts, rather than merely approving mutation of an adopter project root.
4. A tracked script, test, build / packaging surface, or active rule / index outside the target surface or surfaces corroborates that identification and its repo-local maintenance contract, and the change has explicit approval, a scoped diff, compliance with that repository's explicit confidentiality / publication boundary, and repo-local validation.

This path does not decide maintainability by marker presence alone. Preserve unrelated content, modify only the approved source scope, and follow only the validation the repository actually requires, including paired edits or parity when that repository requires them. If a managed block exists, preserve it byte-exactly unless a separately approved adoption operation changes it. This path does not authorize a user-global file, an ordinary adopter project root, an arbitrary tracked instruction file, or an arbitrary whole-file rewrite. If the full source-product root file must be rewritten, the user must separately approve that exact full-file scope and the repo-local maintenance contract must permit it; any existing managed block still remains unchanged without separate adoption approval.

## No project-specific content in the global layer

The global / common layer — the managed-block payload and the distributed toolset — contains only common AI-development operating rules. It must not contain:

- a specific project's architecture description;
- a specific project's current phase or backlog state;
- a per-repository run id or target-specific identifier;
- a target-specific build or test command, except an example explicitly marked as generic.

A project-local instruction may strengthen this boundary but must not weaken or bypass it without separate scoped approval.
