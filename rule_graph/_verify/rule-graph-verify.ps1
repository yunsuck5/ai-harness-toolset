#Requires -Version 5.1
<#
.SYNOPSIS
    rule_graph 의 V1 / V2 / V3 검증기.

.DESCRIPTION
    설계가 정한 세 검사를 구현한다.

      V1  참조 무결성  — 모든 참조가 INDEX 의 살아 있는 key 를 가리키는가  (싸다)
      V3  권위 정합    — 원소가 차단력을 갖지 않는가, 합성이 조합 선언을 갖는가  (중간)
      V2  정본·사본 일치 — 합성에 기재된 사본이 원소 정본과 같은가  (비싸다)

    수동 호출 진단이며 lifecycle hard gate 가 아니다.
    이 스크립트는 읽기만 한다.

.NOTES
    이 파일은 scripts/verify-ps1.ps1 의 스캔 범위 밖이다 (그 스크립트는 scripts/ 만 본다).
    따라서 BOM/CRLF/파서 검사를 자동으로 받지 못한다. 결정 근거는 _journal/DECISIONS_LOG.md D-22.
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

if (-not $ProjectRoot) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}
$graphRoot = Join-Path $ProjectRoot 'rule_graph'

$violations = New-Object System.Collections.Generic.List[string]
$infos = New-Object System.Collections.Generic.List[string]

function Read-Lines([string]$path) {
    return [System.IO.File]::ReadAllLines($path, [System.Text.UTF8Encoding]::new($false))
}

# ---------------------------------------------------------------- INDEX 적재

# INDEX 가 key 의 단일 소유자다. 표 행 하나가 key 하나다.
$indexPath = Join-Path $graphRoot 'INDEX.md'
if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    Write-Output "rule-graph-verify: FAIL: INDEX not found at $indexPath"
    exit 1
}

$index = @{}
foreach ($line in (Read-Lines $indexPath)) {
    $m = [regex]::Match($line, '^\|\s*`(R[EC]-\d{5})`\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|')
    if (-not $m.Success) { continue }
    $key = $m.Groups[1].Value
    if ($index.ContainsKey($key)) {
        $violations.Add("V1 FAIL: duplicate INDEX row for $key")
        continue
    }
    $index[$key] = [pscustomobject]@{
        Key       = $key
        Kind      = $m.Groups[2].Value.Trim()
        State     = $m.Groups[3].Value.Trim()
        Authority = $m.Groups[4].Value.Trim()
        Direction = $m.Groups[5].Value.Trim()
        Path      = $m.Groups[6].Value.Trim().Trim('`')
    }
}

if ($index.Count -eq 0) {
    Write-Output 'rule-graph-verify: FAIL: INDEX has no key rows'
    exit 1
}

# ---------------------------------------------------- 그래프 표면 (E U C + 쿡북)

# F-20: 산문 속 예시 key 가 참조로 잡히면 안 되므로 스캔 대상을 그래프 표면으로 한정한다.
# _journal/ 과 _work/ 는 기록 트리이며 그래프의 일부가 아니다.
$graphSurfaces = New-Object System.Collections.Generic.List[string]
foreach ($sub in @('elements', 'composites')) {
    $dir = Join-Path $graphRoot $sub
    if (Test-Path -LiteralPath $dir -PathType Container) {
        foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.md' -File -Recurse)) {
            $graphSurfaces.Add($f.FullName)
        }
    }
}

# 쿡북은 그래프 밖이지만 참조 주체다 (F-8). 참조 무결성에는 포함하고 역참조에는 포함하지 않는다.
$cookbooks = New-Object System.Collections.Generic.List[string]
$cookbookCandidate = Join-Path $ProjectRoot 'rules\rule-authority.md'
if (Test-Path -LiteralPath $cookbookCandidate -PathType Leaf) { $cookbooks.Add($cookbookCandidate) }

# ------------------------------------------------------------------ 원소 적재

# 원소 정본은 `### RE-xxxxx — 제목` 다음의 첫 `> ` 인용행이다.
$elements = @{}
foreach ($file in $graphSurfaces) {
    if ($file -notmatch '\\elements\\') { continue }
    $lines = Read-Lines $file
    $current = $null
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $h = [regex]::Match($lines[$i], '^###\s+(RE-\d{5})\s')
        if ($h.Success) { $current = $h.Groups[1].Value; continue }
        if ($null -ne $current -and $lines[$i].StartsWith('> ')) {
            if (-not $elements.ContainsKey($current)) {
                $elements[$current] = [pscustomobject]@{
                    Key  = $current
                    Text = $lines[$i].Substring(2).Trim()
                    File = $file
                }
            }
            $current = $null
        }
    }
}

# ------------------------------------------------------------------ 합성 적재

# 합성 하나는 제목행 + 조합 선언 + 규범 문장(`> `) + 사본 행들로 이루어진다.
$composites = @{}
foreach ($file in $graphSurfaces) {
    if ($file -notmatch '\\composites\\') { continue }
    $lines = Read-Lines $file
    $current = $null
    foreach ($line in $lines) {
        $h = [regex]::Match($line, '^###\s+(RC-\d{5})\s')
        if ($h.Success) {
            $current = $h.Groups[1].Value
            $composites[$current] = [pscustomobject]@{
                Key      = $current
                Declared = New-Object System.Collections.Generic.List[string]
                Norm     = $null
                Copies   = New-Object System.Collections.Generic.List[object]
                File     = $file
            }
            continue
        }
        if ($null -eq $current) { continue }
        $c = $composites[$current]

        if ($line -match '\*\*조합\*\*') {
            foreach ($km in [regex]::Matches($line, '\[(R[EC]-\d{5})\]')) {
                $c.Declared.Add($km.Groups[1].Value) | Out-Null
            }
            continue
        }
        if ($null -eq $c.Norm -and $line.StartsWith('> ')) {
            $c.Norm = $line.Substring(2).Trim()
            continue
        }
        $cp = [regex]::Match($line, '^-\s+`\[(R[EC]-\d{5})\]`\s+(.+)$')
        if ($cp.Success) {
            $c.Copies.Add([pscustomobject]@{ Key = $cp.Groups[1].Value; Text = $cp.Groups[2].Value.Trim() }) | Out-Null
        }
    }
}

# --------------------------------------------------------- V1  참조 무결성

$refCount = 0
$backrefs = @{}
foreach ($file in ($graphSurfaces + $cookbooks)) {
    $text = [System.IO.File]::ReadAllText($file, [System.Text.UTF8Encoding]::new($false))
    $rel = $file.Replace($ProjectRoot, '').TrimStart('\')
    foreach ($m in [regex]::Matches($text, '\[(R[EC]-\d{5})\]')) {
        $key = $m.Groups[1].Value
        $refCount++
        if (-not $index.ContainsKey($key)) {
            $violations.Add("V1 FAIL: $rel references $key which is not in INDEX")
            continue
        }
        if ($index[$key].State -eq '반납됨') {
            $violations.Add("V1 FAIL: $rel references $key which has been returned")
        }
        if ($file -notin $cookbooks) {
            if (-not $backrefs.ContainsKey($key)) { $backrefs[$key] = 0 }
            $backrefs[$key]++
        }
    }
}

# 설계: "refs^-1(k) = 0 이 지속되면 강등 - 반납 후보로 부상"
# 실측하면 합성은 구조적으로 다른 합성에 참조되지 않으므로 거의 전부가 후보가 된다 (FINDINGS F-21).
$orphanElements = New-Object System.Collections.Generic.List[string]
$orphanComposites = New-Object System.Collections.Generic.List[string]
foreach ($key in ($index.Keys | Sort-Object)) {
    if ($index[$key].State -eq '반납됨') { continue }
    if ($backrefs.ContainsKey($key)) { continue }
    if ($key.StartsWith('RE-')) { $orphanElements.Add($key) | Out-Null } else { $orphanComposites.Add($key) | Out-Null }
}
$reLive = @($index.Keys | Where-Object { $_.StartsWith('RE-') -and $index[$_].State -ne '반납됨' }).Count
$rcLive = @($index.Keys | Where-Object { $_.StartsWith('RC-') -and $index[$_].State -ne '반납됨' }).Count
$infos.Add("V1 INFO: empty back-reference set within E u C: $($orphanElements.Count)/$reLive element(s), $($orphanComposites.Count)/$rcLive composite(s)")
if ($orphanElements.Count -gt 0) { $infos.Add("V1 INFO:   elements: $($orphanElements -join ', ')") }
if ($orphanComposites.Count -gt 0) { $infos.Add("V1 INFO:   composites: $($orphanComposites -join ', ')") }
$infos.Add('V1 INFO:   the design would treat every one of these as a demotion/return candidate; see FINDINGS F-8 and F-21')

# ---------------------------------------------------------- V3  권위 정합

foreach ($key in ($index.Keys | Sort-Object)) {
    $row = $index[$key]

    if ($key.StartsWith('RE-')) {
        if ($row.Authority -ne 'false') {
            $violations.Add("V3 FAIL: $key is an element but INDEX authority is '$($row.Authority)' (elements cannot block)")
        }
        if ($row.Direction -ne '-' -and $row.Direction -ne '—') {
            $violations.Add("V3 FAIL: $key is an element but carries a blocking direction '$($row.Direction)'")
        }
        if ($row.State -eq '살아있음' -and -not $elements.ContainsKey($key)) {
            $violations.Add("V3 FAIL: $key is live in INDEX but no canonical text was found in elements/")
        }
        continue
    }

    # 합성
    if ($row.State -ne '살아있음') { continue }

    if (-not $composites.ContainsKey($key)) {
        $violations.Add("V3 FAIL: $key is live in INDEX but no declaration was found in composites/")
        continue
    }
    $c = $composites[$key]

    if ($c.Declared.Count -eq 0) {
        $violations.Add("V3 FAIL: $key has no combination declaration (a composite without a declaration does not exist)")
    }
    if ($null -eq $c.Norm) {
        $violations.Add("V3 FAIL: $key has no norm sentence")
    }

    # |S| >= 2 는 방향 '정' 에만 적용한다 (D-7). 방향 '역' 은 슬롯 1 도 인정한다.
    if ($row.Direction -eq '정' -and $c.Declared.Count -lt 2) {
        $violations.Add("V3 FAIL: $key has direction 'jeong' (blocks work) but declares only $($c.Declared.Count) reference(s); |S| >= 2 is required")
    }

    foreach ($d in $c.Declared) {
        if (-not $index.ContainsKey($d)) {
            $violations.Add("V3 FAIL: $key declares $d which is not in INDEX")
        }
    }
}

# --------------------------------------------------- V2  정본·사본 일치

$copyChecked = 0
foreach ($key in ($composites.Keys | Sort-Object)) {
    $c = $composites[$key]
    $rel = $c.File.Replace($ProjectRoot, '').TrimStart('\')

    # 선언한 key 가 사본으로 기재되었는가
    foreach ($d in $c.Declared) {
        if (-not ($c.Copies | Where-Object { $_.Key -eq $d })) {
            $violations.Add("V2 FAIL: $key declares $d but carries no inline copy of it")
        }
    }

    foreach ($copy in $c.Copies) {
        $copyChecked++
        if ($copy.Key.StartsWith('RC-')) {
            # 설계는 사본을 '원소 내용' 으로만 정의했다. 합성을 참조하는 사본의 정본이 무엇인지가 없다.
            $infos.Add("V2 INFO: $key copies composite $($copy.Key); the design does not define the canonical text of a composite copy, so this line is unverifiable")
            continue
        }
        if (-not $elements.ContainsKey($copy.Key)) {
            $violations.Add("V2 FAIL: $rel :: $key copies $($copy.Key) but no canonical element text exists")
            continue
        }
        $canonical = $elements[$copy.Key].Text
        if ($copy.Text -ne $canonical) {
            $violations.Add("V2 FAIL: $key copy of $($copy.Key) differs from canonical text")
            $violations.Add("         canonical: $canonical")
            $violations.Add("         copy     : $($copy.Text)")
        }
    }
}

# ------------------------------------------------------------------- 보고

Write-Output "rule-graph-verify: INDEX keys = $($index.Count); elements with canonical text = $($elements.Count); composites = $($composites.Count)"
Write-Output "rule-graph-verify: V1 scanned $refCount reference(s); V2 compared $copyChecked copy line(s)"
Write-Output 'rule-graph-verify: SCOPE INFO: elements/ + composites/ + cookbook surfaces only; _journal/ and _work/ are records, not graph.'
Write-Output 'rule-graph-verify: SCOPE INFO: manually invoked read-only diagnostic; lifecycle hard gates = 0.'
Write-Output 'rule-graph-verify: LIMITS INFO: V3 cannot decide whether an element text actually blocks; direction is a human judgement (see FINDINGS F-14).'

foreach ($i in $infos) { Write-Output "rule-graph-verify: $i" }

if ($violations.Count -gt 0) {
    foreach ($v in $violations) { Write-Output "rule-graph-verify: $v" }
    Write-Output "rule-graph-verify: FAIL ($($violations.Count) violation line(s))"
    exit 1
}

Write-Output 'rule-graph-verify: PASS (V1 + V2 + V3 over the disclosed scope)'
exit 0
