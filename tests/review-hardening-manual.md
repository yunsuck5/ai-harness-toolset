# review-prepare / review-verify — Manual Hardening Procedure

Deterministic manual validation for the hardening pass on
`scripts/review-prepare.ps1` and `scripts/review-verify.ps1`.

No Pester. No Codex. No commit. No push.

All scratch artifacts are written under:

```
log/evidence/review-hardening/<case>/
```

That path is gitignored via the existing `log/` rule.

## Conventions

- Run all commands from the source repo root (`H:\Work\ai-harness-toolset\ai-harness-toolset`).
- Invoke scripts with `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...`.
- Replace `<id>` placeholders with the actual run id printed by `review-prepare`.

## AC1 — fresh packet pass

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC1 happy path'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -RunId <id>
```

Expected:

- Both commands exit 0.
- `log/review/<id>/meta.json` and `log/review/<id>/input.md` exist.

## AC2 — stale target fails

```powershell
$case = 'log/evidence/review-hardening/ac2'
New-Item -ItemType Directory -Path $case -Force | Out-Null
'first content' | Out-File -FilePath "$case/target.md" -Encoding utf8
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath "$case/target.md" -Stage review -Purpose 'AC2 stale'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <id>
Add-Content -Path "$case/target.md" -Value 'mutation'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <id>
```

Expected:

- First verify exits 0.
- Second verify exits non-zero with a line of the form
  `review-verify: FAIL stale. expected=<sha> actual=<sha>`.

## AC3 — target outside ProjectRoot rejected at prepare

A fake project root and an "outside" target are placed adjacent inside `log/evidence/`.

```powershell
$case = 'log/evidence/review-hardening/ac3'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path "$fake/.ai-harness/templates" -Force | Out-Null
Copy-Item templates/review-input.md "$fake/.ai-harness/templates/review-input.md"
Copy-Item templates/review-meta.json "$fake/.ai-harness/templates/review-meta.json"
'outside body' | Out-File -FilePath "$case/outside.txt" -Encoding utf8
$outside = (Resolve-Path "$case/outside.txt").Path
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -ProjectRoot $fake -ToolRoot "$fake/.ai-harness" `
  -TargetPath $outside -Stage review -Purpose 'AC3 outside'
```

Expected:

- Non-zero exit with `Assert-InProjectRoot: path is outside ProjectRoot...`.
- No directory created under `<fake>/log/review/`.

## AC4 — meta.targetPath outside ProjectRoot rejected at verify

Reuses the AC3 fake project. Prepare against a valid inside file, then hand-edit
`meta.json` to point outside.

```powershell
$case = 'log/evidence/review-hardening/ac4'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path "$fake/.ai-harness/templates" -Force | Out-Null
Copy-Item templates/review-input.md "$fake/.ai-harness/templates/review-input.md"
Copy-Item templates/review-meta.json "$fake/.ai-harness/templates/review-meta.json"
'inside body' | Out-File -FilePath "$fake/inside.md" -Encoding utf8
'outside body' | Out-File -FilePath "$case/outside.txt" -Encoding utf8
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -ProjectRoot $fake -ToolRoot "$fake/.ai-harness" `
  -TargetPath "$fake/inside.md" -Stage review -Purpose 'AC4 prepare'
# Note the printed run id, then hand-edit meta.json:
#   set "targetPath" to the absolute path of <case>/outside.txt
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -ProjectRoot $fake -RunId <id>
```

Expected:

- First prepare/verify pair succeeds.
- After hand-editing, verify exits non-zero with
  `review-verify: FAIL target outside ProjectRoot: ...`.

## AC5 — RunId path traversal rejected

Run each invalid value against both scripts. Use a placeholder valid target for prepare.

```powershell
foreach ($bad in @('../evil','review/evil','C:\evil','a..b','')) {
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
    -TargetPath README.md -Stage review -Purpose 'AC5' -RunId $bad
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId $bad
}
```

Expected:

- Every invocation exits non-zero.
- prepare throws `Assert-ValidRunId: invalid RunId: '<bad>'`.
- verify prints `review-verify: FAIL invalid RunId: <bad>`.
- No directories created outside `<repo>/log/review/`.

The `..`-rejection rule is explicit: `a..b` must be rejected even though it has no
path separator, drive root, or whitespace.

## AC6 — reviewerConfig precedence

(a) Default config present, no CLI overrides:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC6a'
```

Expected `meta.reviewerConfig`: `model=gpt-5.5`, `reasoningEffort=medium`.

(b) CLI overrides:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC6b' `
  -Model gpt-5.4 -ReasoningEffort high
```

Expected `meta.reviewerConfig`: `model=gpt-5.4`, `reasoningEffort=high`.

(c) Built-in default fallback (no config file at all). Reuses the AC8 fixture
without `.ai-harness/config/reviewer.json`:

```powershell
$case = 'log/evidence/review-hardening/ac6c'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path "$fake/.ai-harness/templates" -Force | Out-Null
Copy-Item templates/review-input.md "$fake/.ai-harness/templates/review-input.md"
Copy-Item templates/review-meta.json "$fake/.ai-harness/templates/review-meta.json"
'note' | Out-File -FilePath "$fake/notes.md" -Encoding utf8
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -ProjectRoot $fake -ToolRoot "$fake/.ai-harness" `
  -TargetPath "$fake/notes.md" -Stage review -Purpose 'AC6c built-in defaults'
```

Expected `meta.reviewerConfig`: `model=gpt-5.5`, `fallbackModel=gpt-5.4`,
`reasoningEffort=medium`, `timeoutSeconds=300`, `sandbox=read-only`.

## AC7 — source repo mode

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC7'
```

Expected in meta.json:

- `projectRoot` == `toolRoot` == repo root absolute path.
- `projectLogRoot` == `<repo root>/log`.

## AC8 — target payload mode

Fixture must contain BOTH templates:

```powershell
$case = 'log/evidence/review-hardening/ac8'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path "$fake/.ai-harness/templates" -Force | Out-Null
New-Item -ItemType Directory -Path "$fake/.ai-harness/config" -Force | Out-Null
Copy-Item templates/review-input.md "$fake/.ai-harness/templates/review-input.md"
Copy-Item templates/review-meta.json "$fake/.ai-harness/templates/review-meta.json"
Copy-Item config/reviewer.json "$fake/.ai-harness/config/reviewer.json"
'note' | Out-File -FilePath "$fake/notes.md" -Encoding utf8
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -ProjectRoot $fake -ToolRoot "$fake/.ai-harness" `
  -TargetPath "$fake/notes.md" -Stage review -Purpose 'AC8'
```

Expected:

- `projectRoot` = `<fake>` absolute path.
- `toolRoot` = `<fake>/.ai-harness`.
- `projectLogRoot` = `<fake>/log`.
- Packet under `<fake>/log/review/<id>/`.

## AC9 — encoding policy

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/verify-ps1.ps1
```

Expected: `verify-ps1: PASS (...)`. Spot-check generated `meta.json`/`input.md`:
no UTF-8 BOM, LF line endings.

## AC10 — git cleanliness

```powershell
git status --short
```

Expected: only the five approved file paths
(`scripts/lib/encoding.ps1`, `scripts/lib/path.ps1`, `scripts/review-prepare.ps1`,
`scripts/review-verify.ps1`, `tests/review-hardening-manual.md`) appear.
No `log/` paths are listed.

## Cleanup

`log/evidence/review-hardening/` is gitignored. Leave it after a run for evidence
review, or remove it manually:

```powershell
Remove-Item -Recurse -Force log/evidence/review-hardening
Remove-Item -Recurse -Force log/review
```
