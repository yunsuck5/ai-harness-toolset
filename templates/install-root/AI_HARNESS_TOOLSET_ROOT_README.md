# ai-harness-toolset — global install area

This directory is the **ai-harness-toolset global install area**. The **InstallArea root** is the directory that contains this `README.md` (the runtime payload lives in `current/`, with sibling `install.json` / `payload-manifest.json` / `payload-marker.json`).

This file is an **operator landing page**, not the full operative contract. The full install/update contract is the **latest source clone's `INSTALL.md`** — re-adopt it for any update (see "Updating" below).

## Updating this install ("update to the latest version")

The operator-facing update entrypoint is **`scripts/update-global.ps1`** (existing-install update). The lifecycle entrypoints are named so you pick by name: fresh install = `scripts/install-global.ps1`, **update an existing install = `scripts/update-global.ps1`**, uninstall = `scripts/uninstall-global.ps1`. Normal update flow is **(optional) inspect → update-global → (optional) verify**.

1. **Clone the latest source** and read its `INSTALL.md` — that cloned `INSTALL.md` is the operative contract for the update.
2. Run the **cloned latest source's** `scripts/update-global.ps1` (not this installed copy). Use the cloned latest even if this installed copy already has it — and note a legacy installed payload may **predate** `update-global.ps1` entirely — because the latest source's script + `INSTALL.md` are the update source-of-truth while this installed payload may still be at an older version during bootstrap:
   - `scripts/update-global.ps1 -InstallArea <this directory>`
   - `update-global.ps1` is a thin wrapper: it fail-fasts (and points you to fresh install via `install-global.ps1`) if this is not a valid existing install, otherwise it delegates to the underlying `install-update.ps1 -Mode update-source` and returns its outcome.
3. The read-only checks are run with `install-update.ps1` directly (these are not wrapped by `update-global.ps1`):
   - preflight: `scripts/install-update.ps1 -Mode inspect -InstallArea <this directory>`
   - confirm:  `scripts/install-update.ps1 -Mode verify  -InstallArea <this directory>`
4. For an existing install, pass `-InstallArea <this directory>` and usually **omit `-RepoUrl`** — the source is derived from `install.json`. Passing a differently-spelled URL (for example a `.git`-suffix or trailing-slash difference) can trip the source-cut guard; omitting it is the safe default.
   - `-InstallArea` is **this install-root directory** (the one holding `current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`), **not** `current/`. Passing `current/` is reported as `inspect_mode_unknown` with a "did you mean its parent" hint.

**Underlying / compat path.** `scripts/install-update.ps1 -Mode update-source` is the canonical update **implementation** that `update-global.ps1` wraps. You can call it directly as the compat path (`-Mode inspect` / `-Mode update-source` / `-Mode verify`) — it is unchanged — but `update-global.ps1` is the recommended operator-facing name.

## What update-source does (and does not) do

- `update-source` updates the **payload** (`current/` + the three sibling files) and **verifies activation surfaces by byte-identity only** — it does **not** apply activation.
- If the run reports `activation_pending` (or an activation-only `verify_failed`), the payload is fine and only a **separate, explicit activation apply step** remains — `update-source` does not perform it. `activation_pending` is a follow-up, **not a payload failure** (the run prints `payload=ok` / `result=INCOMPLETE (payload OK; activation follow-up required)`).
- If the run reaches `complete` and activation is already in sync, **no activation re-apply is needed**.

### Applying activation (the follow-up step)

After explicit approval, apply activation with `current/scripts/activate-global.ps1`. It applies **all** verified activation surfaces — the Claude managed block (`CLAUDE.md`), the Codex managed block (`AGENTS.md`, or `AGENTS.override.md` when present), and one canonical-overwrite skill mirror per source skill (`skills/<name>/SKILL.md`; currently the four shipped skills, `ai-harness-review`, `ai-harness-brief`, `ai-harness-consultation`, and `ai-harness-blind-advisory`). Preview first, then apply:

- dry-run preview: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\activate-global.ps1" -Scope All`
- apply: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\activate-global.ps1" -Scope All -Apply`

`-Apply` **modifies your global/user files**, in two mutation classes:

- **Managed blocks** (`CLAUDE.md` / `AGENTS.md`) are spliced **marker-bounded** — your content outside the markers is preserved. Each gets a `<target>.amb-backup` rollback backup, and a clean apply **removes it on success** (leaving none).
- Each **skill mirror** (one per source skill) is a **whole-file canonical overwrite** — the whole `SKILL.md` is replaced from the canonical payload and verified by hash. It has **no backup/rollback**; if a local edit must survive, copy it out first. Recover a failed write by re-running apply or reinstalling.

`-Apply` runs only after an all-surface preflight passes (otherwise it writes nothing). The dry-run previews all surfaces — the managed blocks as a **compact change summary** (add `-ShowFullDiff` for the full before/after), and each skill mirror as source/destination hash + `create | overwrite | unchanged` action + an overwrite notice. Activation is always a **separate explicit step**; `update-source` never applies it and prints these exact commands for you when it reports `activation_pending`.

## Uninstalling this install ("uninstall ai-harness-toolset")

Uninstall is an **official uninstaller flow**, not a manual delete or hand-rewrite. The toolset ships a deterministic uninstaller **inside this same installed package** — find it the way you find the install/update entrypoints: look **inside the package hierarchy**, not just at this install-root top level. The official uninstaller is:

- **`current\scripts\uninstall-global.ps1`** — it lives **under `current\scripts\`** inside this install root, next to `install-global.ps1` / `update-global.ps1` / `activate-global.ps1`. It is **not** at this install-root top level (which holds `README.md` + `current/` + the three sibling `*.json` files, and may also hold a transient `source-cache/` and/or a `log/` run-evidence tree), so discovering it means descending into `current\scripts\` — exactly as you would find the install/update scripts. Do not conclude "there is no uninstaller" from the top level alone.

Run it **dry-run first, then apply** (mirrors the activation flow — default is read-only, no `-Apply`):

- dry-run preview (default): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\uninstall-global.ps1"`
- apply: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\uninstall-global.ps1" -Apply`

With no path arguments it targets the default global install (`%USERPROFILE%\ai-harness-toolset`). `-Apply` reduces the **global ai-harness footprint to zero** and verifies it: this install root (`current/` + the three sibling files + this `README.md`), each owned skill mirror `…\.claude\skills\<name>\` (currently the four shipped skills `ai-harness-review`, `ai-harness-brief`, `ai-harness-consultation`, and `ai-harness-blind-advisory`), and the **managed block** in both instruction files. The two instruction files are **never deleted** — only the marker-bounded `AI_HARNESS_TOOLSET_GLOBAL` span is excised, and your content outside the markers is preserved byte-for-byte.

**Both managed-block surfaces are targeted — including Codex.** The official uninstaller excises the marker span from:

- the Claude managed block in `%USERPROFILE%\.claude\CLAUDE.md`, and
- the **Codex** managed block at `%USERPROFILE%\.codex\AGENTS.md` by default, or `%CODEX_HOME%\AGENTS.md` when the `CODEX_HOME` environment variable is set (an `AGENTS.override.md` in that scope takes precedence when present).

Forgetting the Codex surface is the most common manual-cleanup mistake — the official uninstaller targets it for you, so prefer it over a hand delete.

**A block-only `AGENTS.md` may become 0 bytes — that is the correct outcome, not corruption.** If a Codex `AGENTS.md` (or `AGENTS.override.md`) held *only* the managed block, excising the marker span leaves an empty, 0-byte file. The uninstaller never deletes the user-owned instruction file, so a 0-byte result is the **expected** footprint-zero end state for a block-only file — not damage to recover from.

**Manual cleanup is a fallback, not the flow — and not a dogfood.** Only fall back to hand-deleting the install root or hand-rewriting the managed blocks when the official uninstaller is genuinely unavailable (e.g. a legacy payload that predates `uninstall-global.ps1`) or has failed; for a legacy payload, the in-contract route is to clone the latest source and run its `scripts/uninstall-global.ps1 -InstallArea <this directory>` rather than deleting by hand. A manual partial cleanup is **not** an official uninstall and must **not** be recorded as an uninstall dogfood — manual cleanup easily misses the Codex `%USERPROFILE%\.codex\AGENTS.md` managed block, leaving a stale marker span that then needs a separate corrective removal.

For the full uninstall contract (footprint-zero criterion, the temp-finalizer trampoline, the explicit non-targets, the dry-run/apply/verify split, and the failure tiers), use the **latest source clone's `INSTALL.md`** (§11 (b)).

## Notes

- This `README.md` is a **managed install artifact** — a canonical output of a normal install and of any payload-rewriting `update-source`, materialized deterministically from the in-payload template. `verify` checks that it exists and is byte-identical to that template.
- It is **not self-healing**. A legacy install area may not have it yet; a real install/update (a deterministic overwrite) creates it. If it is missing, stale, or modified on an otherwise up-to-date install, that is an **install integrity failure** — recover with a reinstall (a deterministic overwrite: re-run install, or a payload-rewriting `update-source`), not by relying on a no-op update.
- **Bootstrap clone cleanup.** Any clone you make to **install or update** — the source clone created to read `INSTALL.md` or to run `install-global.ps1`, or the latest-source clone you make to run the update — is a **temporary, one-shot** clone. Remove it once the run closes successfully (fresh install: `installStatus=installed` / `verify_pass` / smoke pass; update: update/activation/verify succeed). A successful run does not need it, and on the success path you should **not** ask or be re-prompted "delete it?" — that re-prompt is a cleanup-contract violation. This operator-created bootstrap clone is separate from the **run-scoped work area** that `install-global.ps1 -RepoUrl` / `update-source` clean up internally. It is also distinct from a `-SourcePath` **local-clone source** you keep as your own working repo — that is your persistent source, not a throwaway bootstrap clone, and is **not** auto-removed (see the latest source clone's `INSTALL.md` for the source-identity distinction). Keep it only on the exception paths — a cleanup failure (report the exact leftover path + reason), an install/update failure, or an explicit investigation / evidence-preserve need; a clone left only because cleanup failed makes the run a **success with cleanup leftover**, not a full lifecycle closeout.
- **`.amb-backup` leftover.** The `.amb-backup` rollback backup belongs **only** to the managed-block surfaces (`CLAUDE.md` / `AGENTS.md`); the skill mirror is a whole-file overwrite with no backup. Activation apply removes its `.amb-backup` on success, so you normally won't see one. A leftover `<target>.amb-backup` next to `CLAUDE.md`/`AGENTS.md` means an apply did not close cleanly — it holds your original bytes, so resolve it before re-applying (a new apply refuses to overwrite an existing one). No automatic cleanup is performed.
- For anything beyond this quick reference, use the **latest source clone's `INSTALL.md`** as the operative contract.
