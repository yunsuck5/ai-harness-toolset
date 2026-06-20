[CmdletBinding()]
param(
    [string] $ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')

$prefix = 'docs-working-model-check: '

function Write-Line {
    param([string] $Message)
    Write-Host ($prefix + $Message)
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot

# This is a repo-structural conformance check that operates purely on whatever
# docs/ + rules/ tree it is pointed at via -ProjectRoot. It is intentionally NOT
# gated by Test-IsSourceRepoRoot (unlike verify-ps1's D8 / Step-F checks, which
# are meaningless outside the source repo): the E1-E3 mechanical checks are
# meaningful for any tree that contains a docs/<candidate>/ incubation folder,
# and the test suite exercises the script against synthetic ProjectRoots that
# carry no source-repo markers.

$violations = New-Object System.Collections.Generic.List[string]

$docsDir = Join-Path -Path $project -ChildPath 'docs'
$rulesDir = Join-Path -Path $project -ChildPath 'rules'
$docsReadme = Join-Path -Path $docsDir -ChildPath 'README.md'
$rulesReadme = Join-Path -Path $rulesDir -ChildPath 'README.md'

# Discover candidate incubation folders: any docs/<candidate>/ directory that
# directly contains at least one *_incubation.md file.
$incubationFolders = New-Object System.Collections.Generic.List[psobject]
if (Test-Path -LiteralPath $docsDir -PathType Container) {
    $candidateDirs = @(Get-ChildItem -LiteralPath $docsDir -Directory -ErrorAction SilentlyContinue)
    foreach ($cand in $candidateDirs) {
        $incFiles = @(Get-ChildItem -LiteralPath $cand.FullName -Filter '*_incubation.md' -File -ErrorAction SilentlyContinue)
        if ($incFiles.Count -gt 0) {
            $hasSpec = @(Get-ChildItem -LiteralPath $cand.FullName -Filter '*_spec.md' -File -ErrorAction SilentlyContinue).Count -gt 0
            $incubationFolders.Add([pscustomobject]@{
                Name           = $cand.Name
                FullName       = $cand.FullName
                IncubationFiles = $incFiles
                HasSpec        = $hasSpec
            }) | Out-Null
        }
    }
}

# Build the set of canonical surface files for E2 scanning:
#   rules/**/*.md + rules/README.md + docs/README.md.
$canonicalFiles = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $rulesDir -PathType Container) {
    $rulesMd = @(Get-ChildItem -LiteralPath $rulesDir -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)
    foreach ($rf in $rulesMd) { $canonicalFiles.Add($rf.FullName) | Out-Null }
}
if (Test-Path -LiteralPath $docsReadme -PathType Leaf) {
    if (-not ($canonicalFiles -contains $docsReadme)) { $canonicalFiles.Add($docsReadme) | Out-Null }
}

# Set of "<folderName>/<incFileName>" path tails for each discovered candidate incubation
# file, used by E2 to confirm a reference resolves to a REAL discovered candidate FILE PATH
# (folder + filename), not merely the same leaf filename in some other / non-existent folder.
$incTails = @()
foreach ($folder in $incubationFolders) {
    foreach ($f in $folder.IncubationFiles) { $incTails += ($folder.Name + '/' + $f.Name) }
}

# ---------------------------------------------------------------------------
# E3 (mechanical, hard FAIL): no canonical-looking sibling in an incubation
# folder. For any docs/<candidate>/ containing a *_incubation.md, assert there
# is NO sibling *_design.md / *_plan.md / *_spec.md in that same directory.
# ---------------------------------------------------------------------------
foreach ($folder in $incubationFolders) {
    foreach ($siblingSuffix in @('*_design.md', '*_plan.md', '*_spec.md')) {
        $siblings = @(Get-ChildItem -LiteralPath $folder.FullName -Filter $siblingSuffix -File -ErrorAction SilentlyContinue)
        foreach ($sib in $siblings) {
            $rel = Resolve-ProjectRelativePath -Path $sib.FullName -ProjectRoot $project
            $violations.Add(('E3 FAIL: canonical-looking sibling created during incubation: {0} (folder docs/{1}/ holds an _incubation document; no _design/_plan/_spec sibling is allowed before promotion)' -f $rel, $folder.Name)) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# E2 (mechanical, hard FAIL): canonical surfaces must not durably reference a
# candidate *_incubation.md. Scan rules/**/*.md + rules/README.md + docs/README.md
# for a path or markdown link that points at a *_incubation.md file. A bare
# mention of the literal token "_incubation" (rule concept) is NOT a violation;
# only an actual path/link to a *_incubation.md file is.
# ---------------------------------------------------------------------------
# A durable reference is an ACTUAL path/link to a real candidate *_incubation.md
# file. It must carry a CONCRETE directory path (a real segment before the
# filename) and must NOT be a template/concept token. Discriminators that mark a
# match as a non-violating concept mention (NOT a durable reference):
#   - it contains an angle-bracket placeholder (e.g. `docs/<candidate>/<candidate>_incubation.md`,
#     `<candidate>_incubation.md`) -> a template pattern, not a real path;
#   - it has no concrete leading directory segment (a bare `_incubation.md` /
#     `foo_incubation.md` filename token, with no real `dir/` before it) -> a
#     rule-concept mention, not a path/link to a located candidate file.
# So a violation requires: <concrete-dir-segment>/ ... /<name>_incubation.md, with
# no '<' / '>' in the reference. The leading dir segment may be `.`/`..` relative.
$incRefPattern = '(?<![A-Za-z0-9_./\\<>-])(?:\.{1,2}[/\\])?(?:[A-Za-z0-9_.\-]+[/\\])+[A-Za-z0-9_.\-]*_incubation\.md'
foreach ($cf in $canonicalFiles) {
    if (-not (Test-Path -LiteralPath $cf -PathType Leaf)) { continue }
    $text = Read-Utf8 -Path $cf
    $m = [regex]::Matches($text, $incRefPattern)
    foreach ($match in $m) {
        # Skip template/concept tokens that carry an angle-bracket placeholder
        # anywhere in the matched reference: those are <candidate>-shaped patterns,
        # not real located paths. (The negative lookbehind already blocks a '<'
        # immediately before the match; this also blocks one mid-reference.)
        if ($match.Value.Contains('<') -or $match.Value.Contains('>')) { continue }
        # Only a reference that resolves to a REAL discovered candidate file PATH
        # (<candidate-folder>/<candidate-file>) is an E2 violation; the same leaf filename in a
        # different / non-existent folder, or an example / historical path, is not.
        $normRef = ($match.Value -replace '\\', '/')
        $isCandidateRef = $false
        foreach ($tail in $incTails) {
            $cmp = [System.StringComparison]::OrdinalIgnoreCase
            if ($normRef.Equals($tail, $cmp) -or $normRef.EndsWith('/' + $tail, $cmp)) {
                $isCandidateRef = $true
                break
            }
        }
        if (-not $isCandidateRef) { continue }
        $rel = Resolve-ProjectRelativePath -Path $cf -ProjectRoot $project
        $violations.Add(('E2 FAIL: canonical surface durably references a candidate _incubation document: {0} -> {1} (a canonical->candidate reference may only be an absorbed-conclusion summary, never a durable path/link)' -f $rel, $match.Value)) | Out-Null
    }
}

# ---------------------------------------------------------------------------
# E1 (mechanical, hard FAIL): a docs/<candidate>/ that holds ONLY _incubation
# file(s) (no promoted canonical *_spec.md) must NOT be referenced as a
# discovery/domain target by docs/README.md or rules/README.md. Conservative
# form: FAIL if either README contains a markdown link or path to that
# docs/<candidate>/ directory or its _incubation.md.
# ---------------------------------------------------------------------------
$e1ReadmeTargets = @($docsReadme, $rulesReadme)
foreach ($folder in $incubationFolders) {
    if ($folder.HasSpec) { continue }   # has a promoted canonical spec -> a domain home, not an incubation-only candidate container
    $name = [regex]::Escape($folder.Name)
    # The reference must denote the candidate's OWN docs/<name>/ folder. Trailing slash is
    # OPTIONAL (a directory link is commonly written without it, e.g. [x](scopeguard)). To avoid
    # flagging a bare plain-text name mention (allowed thin metadata), the slash-less relative
    # form is honored ONLY in markdown link-target position "](...".
    #   - docs-rooted (valid from either README): (./|../)*docs/<name>  (sub-path / slash / end OK)
    #   - docs-relative link (valid ONLY from docs/README.md): "](" (./)?<name>
    # Trailing (?![A-Za-z0-9_-]) prevents matching <name> as a prefix of a longer folder name.
    $docsRootedPattern = '(?<![A-Za-z0-9_./\\-])(?:\.{1,2}[/\\])*docs[/\\]' + $name + '(?![A-Za-z0-9_-])'
    $docsRelativeLinkPattern = '\]\(\s*<?\s*(?:\.[/\\])?' + $name + '(?![A-Za-z0-9_-])'
    foreach ($readme in $e1ReadmeTargets) {
        if (-not (Test-Path -LiteralPath $readme -PathType Leaf)) { continue }
        $rtext = Read-Utf8 -Path $readme
        $isDocsReadme = ($readme -eq $docsReadme)
        $hit = [regex]::IsMatch($rtext, $docsRootedPattern)
        if ((-not $hit) -and $isDocsReadme) { $hit = [regex]::IsMatch($rtext, $docsRelativeLinkPattern) }
        if ($hit) {
            $rel = Resolve-ProjectRelativePath -Path $readme -ProjectRoot $project
            $violations.Add(('E1 FAIL: incubation-only candidate folder is referenced as a discovery/domain target: {0} links/points at docs/{1}/ (a folder holding only _incubation.md is a non-domain candidate container; thin name/owner/review-date metadata is allowed, a domain-home link/path is not)' -f $rel, $folder.Name)) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Line ('scanned ProjectRoot {0}; found {1} incubation candidate folder(s)' -f $project, $incubationFolders.Count)
Write-Line 'SCOPE INFO: MECHANICAL subset only. Scanned: E1 = docs/README.md + rules/README.md; E2 = all .md under rules/ (recursive, so any package-local templates/ or checklists/ under a rule ARE included) + docs/README.md; E3 = _design/_plan/_spec siblings of docs/<candidate>/ incubation folders. E4/E5 are advisory only (not enforced). Any canonical surface outside those exact globs (e.g. repo-root templates/, snippets/ and skills, generator inputs, docs/** other than docs/README.md) is NOT mechanically scanned (manual conformance). A PASS attests only to the scanned subset, not full incubation-tier conformance.'

if ($violations.Count -gt 0) {
    foreach ($v in $violations) {
        Write-Line $v
    }
}

# E4 (advisory only — never FAILs): absorption-content completeness is a
# manual/semantic check, not mechanically enforced.
Write-Line 'E4 INFO: absorption-content completeness (adopted conclusion / rejected alternatives / evidence-type / scope / failure criteria / known negative evidence) is a manual/semantic check, not mechanically enforced here.'

# E5 (not mechanized — one info line): the rule's own incubation-tier addition
# is a one-time bootstrap invariant.
Write-Line 'E5 INFO: this rule''s own incubation-tier addition is a one-time bootstrap (incubation cannot incubate itself), not mechanically checked and not a precedent.'

if ($violations.Count -gt 0) {
    Write-Line ('FAIL ({0} E1/E2/E3 violation(s) in the mechanically-scanned subset)' -f $violations.Count)
    exit 1
}

Write-Line 'PASS (no E1/E2/E3 violations in the mechanically-scanned subset)'
exit 0
