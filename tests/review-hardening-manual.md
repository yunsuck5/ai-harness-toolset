# review-prepare / review-verify — Manual Hardening Procedure

Deterministic manual validation for the hardening pass on
`scripts/review-prepare.ps1` and `scripts/review-verify.ps1`.

No Pester. No Codex. No commit. No push.

All scratch artifacts are written under:

```
log/evidence/review-hardening/<case>/
```

That path is gitignored via the existing `log/` rule. The path follows the
`<ProjectRoot>/log/evidence/<scope>/<case>/` convention defined in
`docs/EVIDENCE_CONTRACT.md`, where `review-hardening` is the `<scope>` and each
`AC*` directory is the `<case>` workspace. This procedure uses each case
directory primarily as a fixture workspace; the contract's recommended
`command.txt` / `exit-code.txt` files are not required by this manual run, but
may be added per case if a runner wants to record execution facts.

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

Expected: only the four approved file paths for the ProjectLogRoot resolution
hardening scope appear:

- `scripts/lib/path.ps1`
- `scripts/log-init.ps1`
- `scripts/review-verify.ps1`
- `tests/review-hardening-manual.md`

No `log/` paths are listed.

## AC11 — `Get-ProjectLogRoot` normalization

Confirms that `meta.projectLogRoot` is a single canonical full path regardless of
how `-ProjectRoot` was spelled. Reuses an AC8-shaped fake project so we never
have to mutate the source repo's own `log/`.

```powershell
$case = 'log/evidence/review-hardening/ac11'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path "$fake/.ai-harness/templates" -Force | Out-Null
New-Item -ItemType Directory -Path "$fake/.ai-harness/config"    -Force | Out-Null
Copy-Item templates/review-input.md "$fake/.ai-harness/templates/review-input.md"
Copy-Item templates/review-meta.json "$fake/.ai-harness/templates/review-meta.json"
Copy-Item config/reviewer.json       "$fake/.ai-harness/config/reviewer.json"
'note' | Out-File -FilePath "$fake/notes.md" -Encoding utf8

$canonical = (Resolve-Path $fake).Path
$variants  = @(
    $canonical,
    ($canonical + [System.IO.Path]::DirectorySeparatorChar),
    ($canonical -replace '\\','/')
)

foreach ($pr in $variants) {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
      -ProjectRoot $pr -ToolRoot "$fake/.ai-harness" `
      -TargetPath "$fake/notes.md" -Stage review -Purpose 'AC11 normalization'
}
```

Expected:

- For every variant, `meta.projectLogRoot` is byte-identical to the canonical
  `<fake>\log` form. This is the load-bearing invariant for this batch.
- For every variant, `meta.projectRoot` is identical to the canonical `<fake>`
  form **after trailing `\` is trimmed**. The forward-slash variant is fully
  back-slashed; the trailing-separator variant retains its trailing `\` because
  `Get-ProjectRoot` is intentionally unchanged in this scope. The
  `review-verify` cross-check trims trailing separators on both sides before
  equality, so this drift cannot cause a false mismatch.
- All three runs exit 0.

## AC12 — `log-init` containment (positive)

Validates that `log-init.ps1` only creates directories exactly under
`<ProjectRoot>/log/`. No production function is monkey-patched.

```powershell
$case = 'log/evidence/review-hardening/ac12'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path $fake -Force | Out-Null
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/log-init.ps1 -ProjectRoot $fake
$expected = @(
    (Join-Path $fake 'log'),
    (Join-Path $fake 'log/chatlog'),
    (Join-Path $fake 'log/evidence'),
    (Join-Path $fake 'log/review')
)
$expected | ForEach-Object {
    if (-not (Test-Path -LiteralPath $_ -PathType Container)) { throw "missing: $_" }
}
$actual = Get-ChildItem -LiteralPath (Join-Path $fake 'log') -Directory -Recurse |
          Select-Object -ExpandProperty FullName
$canonicalLog = [System.IO.Path]::GetFullPath((Join-Path $fake 'log'))
foreach ($a in $actual) {
    if (-not $a.StartsWith($canonicalLog, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "outside ProjectLogRoot: $a"
    }
}
```

Expected:

- `log-init.ps1` exits 0.
- All four expected directories exist.
- No directory under `<fake>/log` lies outside the canonical `<fake>/log` prefix.

## AC13 — `review-verify` cross-check against meta

Catches the case where a packet was prepared in one project root but verified
against another. Prepare in fake project A, copy the run dir into fake project B,
then verify with `-ProjectRoot` pointed at B.

```powershell
$case = 'log/evidence/review-hardening/ac13'
$fakeA = "$case/projectA"
$fakeB = "$case/projectB"
foreach ($f in @($fakeA, $fakeB)) {
    New-Item -ItemType Directory -Path "$f/.ai-harness/templates" -Force | Out-Null
    New-Item -ItemType Directory -Path "$f/.ai-harness/config"    -Force | Out-Null
    Copy-Item templates/review-input.md "$f/.ai-harness/templates/review-input.md"
    Copy-Item templates/review-meta.json "$f/.ai-harness/templates/review-meta.json"
    Copy-Item config/reviewer.json       "$f/.ai-harness/config/reviewer.json"
    'note' | Out-File -FilePath "$f/notes.md" -Encoding utf8
}
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -ProjectRoot $fakeA -ToolRoot "$fakeA/.ai-harness" `
  -TargetPath "$fakeA/notes.md" -Stage review -Purpose 'AC13 prepare in A'
# Note the printed run id, then mirror that run dir into B:
New-Item -ItemType Directory -Path "$fakeB/log/review" -Force | Out-Null
Copy-Item -Recurse "$fakeA/log/review/<id>" "$fakeB/log/review/<id>"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -ProjectRoot $fakeB -RunId <id>
```

Expected:

- Verify exits non-zero.
- One of two deterministic FAIL messages is printed:
  - `review-verify: FAIL projectRoot mismatch. meta=<A> runtime=<B>`, or
  - `review-verify: FAIL projectLogRoot mismatch. meta=<A>\log runtime=<B>\log`.
- The check fires **before** target-sha256 comparison.

## AC14 — `Assert-InProjectLogRoot` direct helper checks

Loads the helper directly to confirm both inside-pass and outside-throw paths.

```powershell
. .\scripts\lib\path.ps1
$case = 'log/evidence/review-hardening/ac14'
$fake = "$case/fakeproject"
New-Item -ItemType Directory -Path "$fake/log/chatlog" -Force | Out-Null
New-Item -ItemType Directory -Path "$case/outsidearea" -Force | Out-Null

$logRoot = Get-ProjectLogRoot -ProjectRoot $fake
$inside  = Join-Path $logRoot 'chatlog/sample.md'
$outside = (Resolve-Path "$case/outsidearea").Path

# Inside cases
[void] (Assert-InProjectLogRoot -Path $logRoot                        -ProjectLogRoot $logRoot)
[void] (Assert-InProjectLogRoot -Path (Join-Path $logRoot 'chatlog')  -ProjectLogRoot $logRoot)
[void] (Assert-InProjectLogRoot -Path $inside                         -ProjectLogRoot $logRoot)

# Outside case
$threw = $false
try { [void] (Assert-InProjectLogRoot -Path $outside -ProjectLogRoot $logRoot) }
catch { $threw = $true; $_.Exception.Message }
if (-not $threw) { throw 'AC14: expected outside path to throw' }
```

Expected:

- All three inside calls return `$true` silently.
- The outside call throws with a message starting `Assert-InProjectLogRoot: path is outside ProjectLogRoot. Path=...`.

## AC15 — default mode regression: missing result.md/result.json is not a failure

Confirms that `review-verify` without `-RequireResult` continues to treat missing
result artifacts as informational only.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC15 default mode regression'
# Note the printed run id, then verify without -RequireResult:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <id>
```

Expected:

- Exit 0.
- Output includes either `review-verify: result.md not present (informational)` or
  `review-verify: result.md present (informational)` depending on whether the run
  directory contains `result.md`.
- Output ends with `review-verify: PASS run-id <id>`.
- No new FAIL line is emitted because of missing `result.md` / `result.json`.

## AC16 — `-RequireResult` happy path

Prepares a packet, hand-authors `result.md` and `result.json` per
`docs/REVIEW_RESULT_CONTRACT.md`, then verifies with `-RequireResult`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC16 require-result happy'
# Note the printed run id. Then write result.md and result.json under
# log/review/<id>/, copying the verdict / Target / Input binding sections from
# templates/review-result.md and templates/review-result.json. Populate:
#   - meta.runId          -> result.runId
#   - meta.targetSha256   -> result.targetSha256
#   - SHA256(input.md)    -> result.inputSha256
#   - SHA256(result.md)   -> result.resultMarkdownSha256  (compute AFTER result.md is final)
#   - verdict             -> 'yes' | 'no' | 'yes with risk' (exact value, no normalization)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -RunId <id> -RequireResult
```

Expected:

- Exit 0.
- Output includes `review-verify: result.json present and binding verified`.
- Output ends with `review-verify: PASS run-id <id>`.
- The default-mode informational `result.md present (informational)` line is also
  printed (default checks run before the `-RequireResult` block).

## AC17 — `-RequireResult` missing result.md fails

Reuses an AC16-style preparation but does not author `result.md`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC17 missing result.md'
# Note the printed run id. Do NOT create result.md in the run directory.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -RunId <id> -RequireResult
```

Expected:

- Non-zero exit.
- A line of the form `review-verify: FAIL result.md missing: <runDir>\result.md`.
- The default-mode informational `result.md not present (informational)` line is
  printed first (default checks always run, the `-RequireResult` block then
  promotes the missing file to a hard failure).

## AC18 — `-RequireResult` targetSha256 mismatch fails

Authors a complete record (as in AC16) but hand-edits
`result.json.targetSha256` to a different value.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC18 targetSha256 mismatch'
# Note the printed run id. Author result.md and result.json as in AC16, then
# hand-edit result.json so result.targetSha256 differs from meta.targetSha256
# (e.g., flip a single hex character).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -RunId <id> -RequireResult
```

Expected:

- Non-zero exit.
- Output line of the form
  `review-verify: FAIL result.json targetSha256 mismatch. meta=<sha-from-meta> result=<sha-from-result>`.
- Default-mode `FAIL stale ...` does NOT fire here because the on-disk target
  file was never modified — the failure is a `result.json` binding mismatch, not
  a freshness failure.

## AC19 — `-RequireResult` invalid verdict fails

Authors a complete record (as in AC16) but uses a verdict value outside the
allowed enum.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
  -TargetPath README.md -Stage review -Purpose 'AC19 invalid verdict'
# Note the printed run id. Author result.md and result.json as in AC16 with all
# binding fields populated correctly, but set result.verdict to something outside
# the allowed enum, for example "approved" or "Yes With Risk" (case differs).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 `
  -RunId <id> -RequireResult
```

Expected:

- Non-zero exit.
- Output line of the form
  `review-verify: FAIL result.json verdict invalid: '<value>'`.
- The check fires only after all binding-hash checks pass, so binding mismatches
  in the same `result.json` would short-circuit before this line.

## Cleanup

`log/evidence/review-hardening/` is gitignored. Leave it after a run for evidence
review, or remove it manually:

```powershell
Remove-Item -Recurse -Force log/evidence/review-hardening
Remove-Item -Recurse -Force log/review
```
