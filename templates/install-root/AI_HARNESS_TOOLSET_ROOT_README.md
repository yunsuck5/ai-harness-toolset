# ai-harness-toolset — global install area

This directory is the **ai-harness-toolset global install area**. The **InstallArea root** is the directory that contains this `README.md` (the runtime payload lives in `current/`, with sibling `install.json` / `payload-manifest.json` / `payload-marker.json`).

This file is an **operator landing page**, not the full operative contract. The full install/update contract is the **latest source clone's `INSTALL.md`** — re-adopt it for any update (see "Updating" below).

## Updating this install ("update to the latest version")

Normal update flow is three steps: **inspect → update-source → verify**.

1. **Clone the latest source** and read its `INSTALL.md` — that cloned `INSTALL.md` is the operative contract for the update.
2. Run the **cloned latest source's** `scripts/install-update.ps1` (not this installed copy) — even if this installed copy already has an `update-source` mode, the latest source's script + `INSTALL.md` are the update source-of-truth, because this installed payload may still be at an older version during bootstrap:
   - `scripts/install-update.ps1 -Mode inspect      -InstallArea <this directory>`
   - `scripts/install-update.ps1 -Mode update-source -InstallArea <this directory>`
   - `scripts/install-update.ps1 -Mode verify        -InstallArea <this directory>`
3. For an existing install, pass `-InstallArea <this directory>` and usually **omit `-RepoUrl`** — the script derives the source from `install.json`. Passing a differently-spelled URL (for example a `.git`-suffix or trailing-slash difference) can trip the source-cut guard; omitting it is the safe default.
   - `-InstallArea` is **this install-root directory** (the one holding `current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`), **not** `current/`. Passing `current/` is reported as `inspect_mode_unknown` with a "did you mean its parent" hint.

## What update-source does (and does not) do

- `update-source` updates the **payload** (`current/` + the three sibling files) and **verifies activation surfaces by byte-identity only** — it does **not** apply activation.
- If the run reports `activation_pending` (or an activation-only `verify_failed`), the payload is fine and only a **separate, explicit activation apply step** remains — `update-source` does not perform it. `activation_pending` is a follow-up, **not a payload failure** (the run prints `payload=ok` / `result=INCOMPLETE (payload OK; activation follow-up required)`).
- If the run reaches `complete` and activation is already in sync, **no activation re-apply is needed**.

### Applying activation (the follow-up step)

After explicit approval, apply activation with `current/scripts/activate-global.ps1`. Preview first, then apply:

- dry-run preview: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\activate-global.ps1" -Scope All`
- apply: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\activate-global.ps1" -Scope All -Apply`

`-Apply` **modifies your global instruction files** (`CLAUDE.md` / `AGENTS.md`). During each surface's apply it creates a `<target>.amb-backup` rollback backup and **removes it on success** — a clean apply leaves no `.amb-backup` behind. The dry-run prints a **compact change summary** by default; add `-ShowFullDiff` for the full managed-block before/after. (`update-source` prints these exact commands for you when it reports `activation_pending`.)

## Notes

- This `README.md` is a **managed install artifact** — a canonical output of a normal install and of any payload-rewriting `update-source`, materialized deterministically from the in-payload template. `verify` checks that it exists and is byte-identical to that template.
- It is **not self-healing**. A legacy install area may not have it yet; a real install/update (a deterministic overwrite) creates it. If it is missing, stale, or modified on an otherwise up-to-date install, that is an **install integrity failure** — recover with a reinstall (a deterministic overwrite: re-run install, or a payload-rewriting `update-source`), not by relying on a no-op update.
- **Bootstrap clone cleanup.** The latest-source clone you make to run the update is a **temporary, one-shot** clone — remove it once the update/activation/verify succeed. A successful run does not need it, and you should not be re-prompted to keep it; keep it only if a cleanup fails or you need it for investigation.
- **`.amb-backup` leftover.** Activation apply removes its `.amb-backup` rollback backup on success, so you normally won't see one. A leftover `<target>.amb-backup` next to `CLAUDE.md`/`AGENTS.md` means an apply did not close cleanly — it holds your original bytes, so resolve it before re-applying (a new apply refuses to overwrite an existing one). No automatic cleanup is performed.
- For anything beyond this quick reference, use the **latest source clone's `INSTALL.md`** as the operative contract.
