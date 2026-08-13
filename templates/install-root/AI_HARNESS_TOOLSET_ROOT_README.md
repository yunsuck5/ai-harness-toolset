# ai-harness-toolset — global install area

This directory is the **ai-harness-toolset global install area**. The **InstallArea root** is the directory that contains this `README.md` (the runtime payload lives in `current/`, with sibling `install.json` / `payload-manifest.json` / `payload-marker.json`).

This file is an **operator landing page**, not the full operative contract. The full install/update contract is the **latest source clone's `INSTALL.md`** — re-adopt it for any update (see "Updating" below).

## 이 install 업데이트하기 ("최신 버전으로 업데이트")

기존 install의 operator-facing 진입점은 **`scripts/update-global.ps1`**이다. fresh install은 `scripts/install-global.ps1`, 기존 install update는 `scripts/update-global.ps1`, uninstall은 `scripts/uninstall-global.ps1`을 사용한다. 정상 순서는 **inspect → update-global → (선택) verify**다.

1. 이 install의 `install.json`을 읽고 git-url target을 명시적으로 고른다. recorded branch가 non-empty이면 그 exact branch ref의 현재 advertised HEAD를 40-hex SHA로 고정한다. branch가 empty이면 remote symbolic/default HEAD의 SHA가 현재 advertised branch tip인지 확인해 exact `-Ref`만 사용하고 branch를 추정하거나 기록하지 않는다.
2. source를 temporary clone한 뒤 selected SHA를 `git -C <bootstrap-clone> checkout --detach <resolved SHA>`로 checkout하고 `git -C <bootstrap-clone> rev-parse HEAD`가 그 SHA와 정확히 같은지 확인한다. 이 equality를 확인하기 전에는 clone의 `INSTALL.md`나 script를 읽거나 실행하지 않는다.
3. verified exact checkout의 `INSTALL.md`를 operative contract로 읽고, 같은 checkout의 read-only preflight를 같은 target으로 실행한다:
   - `scripts/install-update.ps1 -Mode inspect -InstallArea <this directory> -Ref <resolved 40-hex SHA>`
4. **같은 verified checkout**의 update entrypoint를 같은 target으로 실행한다(설치된 사본이 아니다). legacy payload에는 `update-global.ps1` 자체가 없을 수 있다:
   - `scripts/update-global.ps1 -InstallArea <this directory> -Ref <the same resolved 40-hex SHA>`
   - `update-global.ps1`은 valid existing install을 확인한 뒤 `install-update.ps1 -Mode update-source`에 delegate하는 thin wrapper다. `activation_pending`은 FAIL이 아니라 **INCOMPLETE**로 유지하고, `-Json`에서는 delegate JSON만 stdout에 둔다.
5. 갱신 후 read-only verifier로 확인한다:
   - `scripts/install-update.ps1 -Mode verify -InstallArea <this directory>`
6. git-url inspect/update는 target selector를 정확히 하나 요구한다: exact one-shot `-Ref <advertised 40-hex branch-tip commit>` 또는 non-empty recorded `-Branch <branch>`. 생략하거나 둘을 함께 넘기지 않는다. `-Ref`는 recorded branch와 remote를 빈 값까지 보존한다. moving `-Branch`가 bootstrap SHA와 다른 SHA를 resolve하면 새 target을 checkout·검증하고 그 target의 `INSTALL.md`를 다시 읽기 전에는 update하지 않는다.
7. 기존 git-url install에서는 보통 `-RepoUrl`을 생략하고 `-SourcePath`는 절대 넘기지 않는다. URL은 `install.json`에서 오고 target은 위 selector가 정한다. `-SourcePath`는 inspect와 apply가 다른 source를 볼 수 있어 거부된다.
   - `-InstallArea`는 `current/`가 아니라 `current/`와 세 sibling JSON을 담은 **install-root directory**다. `current/`를 넘기면 parent hint와 함께 `inspect_mode_unknown`으로 보고된다.

**Underlying / compat path.** `scripts/install-update.ps1 -Mode update-source`는 `update-global.ps1`이 감싸는 canonical implementation이다. git-url에서는 같은 필수 selector와 함께 직접 호출할 수 있고, local-clone에서는 git-url selector를 넘기지 않는다. operator-facing 이름은 `update-global.ps1`을 권장한다.

## What update-source does (and does not) do

- `update-source` updates the **payload** (`current/` + the three sibling files) and **verifies activation surfaces by byte-identity only** — it does **not** apply activation.
- If the run reports `activation_pending` (or an activation-only `verify_failed`), the payload is fine and only a **separate, explicit activation apply step** remains — `update-source` does not perform it. `activation_pending` is a follow-up, **not a payload failure** (the run prints `payload=ok` / `result=INCOMPLETE (payload OK; activation follow-up required)`).
- If the run reaches `complete` and activation is already in sync, **no activation re-apply is needed**.

### Applying activation (the follow-up step)

After explicit approval, apply activation with `current/scripts/activate-global.ps1`. It applies **all** verified activation surfaces — the Claude managed block (`CLAUDE.md`), the Codex managed block (`AGENTS.md`, or `AGENTS.override.md` when present), and one canonical-overwrite skill mirror in **each vendor home** per source skill (`skills/<name>/SKILL.md`; currently the four shipped skills, `ai-harness-review`, `ai-harness-brief`, `ai-harness-consultation`, and `ai-harness-blind-advisory`). Preview first, then apply:

- dry-run preview: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\activate-global.ps1" -Scope All`
- apply: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\activate-global.ps1" -Scope All -Apply`

`-Apply` **modifies your global/user files**, in two mutation classes:

- **Managed blocks** (`CLAUDE.md` / `AGENTS.md`) are spliced **marker-bounded** — your content outside the markers is preserved. Each gets a `<target>.amb-backup` rollback backup, and a clean apply **removes it on success** (leaving none).
- Each **skill mirror** (one per vendor per source skill) is a **whole-file canonical overwrite** — the whole `SKILL.md` is replaced from the canonical payload and verified by hash. It has **no backup/rollback**; if a local edit must survive, copy it out first. Recover a failed write by re-running apply or reinstalling.

`-Apply` runs only after an all-surface preflight passes (otherwise it writes nothing). The dry-run previews all surfaces — the managed blocks as a **compact change summary** (add `-ShowFullDiff` for the full before/after), and each skill mirror as source/destination hash + `create | overwrite | unchanged` action + an overwrite notice. Activation is always a **separate explicit step**; `update-source` never applies it and prints these exact commands for you when it reports `activation_pending`.

## Uninstalling this install ("uninstall ai-harness-toolset")

Uninstall is an **official uninstaller flow**, not a manual delete or hand-rewrite. The toolset ships a deterministic uninstaller **inside this same installed package** — find it the way you find the install/update entrypoints: look **inside the package hierarchy**, not just at this install-root top level. The official uninstaller is:

- **`current\scripts\uninstall-global.ps1`** — it lives **under `current\scripts\`** inside this install root, next to `install-global.ps1` / `update-global.ps1` / `activate-global.ps1`. It is **not** at this install-root top level (which holds `README.md` + `current/` + the three sibling `*.json` files, and may also hold a transient `source-cache/` and/or a `log/` run-evidence tree), so discovering it means descending into `current\scripts\` — exactly as you would find the install/update scripts. Do not conclude "there is no uninstaller" from the top level alone.

Run it **dry-run first, then apply** (mirrors the activation flow — default is read-only, no `-Apply`):

- dry-run preview (default): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\uninstall-global.ps1"`
- apply: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "current\scripts\uninstall-global.ps1" -Apply`

With no path arguments it targets the default global install (`%USERPROFILE%\ai-harness-toolset`). `-Apply` reduces the **global ai-harness footprint to zero** and verifies it: this install root (`current/` + the three sibling files + this `README.md`), each owned skill mirror under both vendor homes' `skills\<name>\` directories (currently the four shipped skills `ai-harness-review`, `ai-harness-brief`, `ai-harness-consultation`, and `ai-harness-blind-advisory`), and the **managed block** in both instruction files. The two instruction files are **never deleted** — only the marker-bounded `AI_HARNESS_TOOLSET_GLOBAL` span is excised, and your content outside the markers is preserved byte-for-byte.

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
