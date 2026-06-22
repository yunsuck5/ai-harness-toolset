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

# Discover candidate incubation folders. Two candidate homes (Incubation tier is
# pre-promotion for a domain OR a rule candidate):
#   - domain candidate: docs/<candidate>/ containing a *_incubation.md
#   - rule candidate:   rule_docs/<candidate>/ containing a *_incubation.md
# Each folder records its base tree (docs / rule_docs) so the E1 README-reference
# pattern and the E1/E3 messages target the correct tree.
$incubationFolders = New-Object System.Collections.Generic.List[psobject]
$ruleDocsDir = Join-Path -Path $project -ChildPath 'rule_docs'
foreach ($base in @(
        [pscustomobject]@{ Dir = $docsDir;    Rel = 'docs' },
        [pscustomobject]@{ Dir = $ruleDocsDir; Rel = 'rule_docs' })) {
    if (-not (Test-Path -LiteralPath $base.Dir -PathType Container)) { continue }
    $candidateDirs = @(Get-ChildItem -LiteralPath $base.Dir -Directory -ErrorAction SilentlyContinue)
    foreach ($cand in $candidateDirs) {
        $incFiles = @(Get-ChildItem -LiteralPath $cand.FullName -Filter '*_incubation.md' -File -ErrorAction SilentlyContinue)
        if ($incFiles.Count -gt 0) {
            $hasSpec = @(Get-ChildItem -LiteralPath $cand.FullName -Filter '*_spec.md' -File -ErrorAction SilentlyContinue).Count -gt 0
            $incubationFolders.Add([pscustomobject]@{
                Name           = $cand.Name
                FullName       = $cand.FullName
                IncubationFiles = $incFiles
                HasSpec        = $hasSpec
                BaseRel        = $base.Rel
            }) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# rule_docs structural conformance (mechanical, hard FAIL): rule_docs/ is the
# per-rule, 1:1 rule-bound planning workspace. Each direct child rule_docs/<id>/
# is a PERSISTENT per-rule folder snapshot-distinguishable into exactly THREE
# valid states (docs-working-model rule, Incubation tier > rule_docs purity):
#   - idle              = files are EXACTLY {.gitkeep}; valid ONLY if a
#                         corresponding existing rule output file exists
#                         (rules/<id>/<id>.md OR snippets/rules/<id>.md).
#                         No corresponding rule output -> RULE_DOCS-ORPHAN
#                         (a discarded candidate's / deleted rule's folder left behind).
#   - candidate incubation = contains <id>_incubation.md (may also carry a round-scoped
#                         <id>_work_packet.md; E3 still forbids _design/_plan/_spec
#                         siblings); valid, need NOT have a rule output yet.
#   - active lifecycle work = contains one or more of
#                         <id>_design.md / <id>_plan.md / <id>_work_packet.md; valid.
# Allowed files in a child: ONLY .gitkeep or
#   <id>_{incubation,design,plan,work_packet}.md (.md only). Anything else
#   (README / archive / consumed / old / misc / mismatched-id / non-.md) is a
#   RULE_DOCS-FILE violation; a subfolder is a RULE_DOCS-FILE violation. A loose
#   file DIRECTLY under rule_docs/ (not inside a <id>/ child) is RULE_DOCS-PURITY.
# This is a STRUCTURE (snapshot) check only: it deletes nothing and must not flag
# a valid idle .gitkeep folder. (docs/ is intentionally looser -- it also holds
# live domain Specs + docs/README.md -- so this binds only rule_docs/.)
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $ruleDocsDir -PathType Container) {
    foreach ($child in @(Get-ChildItem -LiteralPath $ruleDocsDir -Force -ErrorAction SilentlyContinue)) {
        $rel = Resolve-ProjectRelativePath -Path $child.FullName -ProjectRoot $project
        if (-not $child.PSIsContainer) {
            # Loose file directly under rule_docs/ -- not inside a <id>/ child.
            $violations.Add(('RULE_DOCS-PURITY FAIL: loose file directly under rule_docs/: {0} (rule_docs holds only per-rule folders rule_docs/<id>/; no top-level files and no orientation README)' -f $rel)) | Out-Null
            continue
        }

        $id = $child.Name
        $allowedNames = @(
            '.gitkeep',
            ($id + '_incubation.md'),
            ($id + '_design.md'),
            ($id + '_plan.md'),
            ($id + '_work_packet.md'))
        $cmp = [System.StringComparison]::OrdinalIgnoreCase

        # Enumerate the folder's direct entries. No subfolders allowed; every file
        # must be in the allowed set (snapshot validation only -- nothing removed).
        $entries = @(Get-ChildItem -LiteralPath $child.FullName -Force -ErrorAction SilentlyContinue)
        $hasIncubation = $false
        $hasLifecycle  = $false
        $hasGitkeep    = $false
        $allowedFileCount = 0
        foreach ($entry in $entries) {
            $entryRel = Resolve-ProjectRelativePath -Path $entry.FullName -ProjectRoot $project
            if ($entry.PSIsContainer) {
                $violations.Add(('RULE_DOCS-FILE FAIL: disallowed subfolder under rule_docs/{0}/: {1} (a per-rule folder holds only .gitkeep or {0}_{{incubation,design,plan,work_packet}}.md; no subfolders)' -f $id, $entryRel)) | Out-Null
                continue
            }
            $isAllowed = $false
            foreach ($an in $allowedNames) {
                if ([string]::Equals($entry.Name, $an, $cmp)) { $isAllowed = $true; break }
            }
            if (-not $isAllowed) {
                $violations.Add(('RULE_DOCS-FILE FAIL: disallowed file under rule_docs/{0}/: {1} (allowed: .gitkeep or {0}_{{incubation,design,plan,work_packet}}.md, .md only; no README/archive/consumed/old/misc or mismatched-id files)' -f $id, $entryRel)) | Out-Null
                continue
            }
            $allowedFileCount++
            if ([string]::Equals($entry.Name, '.gitkeep', $cmp)) { $hasGitkeep = $true }
            elseif ([string]::Equals($entry.Name, ($id + '_incubation.md'), $cmp)) { $hasIncubation = $true }
            else { $hasLifecycle = $true }  # _design / _plan / _work_packet
        }

        # State determination on the ALLOWED files present.
        if ($hasIncubation -or $hasLifecycle) {
            # candidate incubation OR active lifecycle work -> valid; need not have
            # a rule output yet (incubation) or is a normal existing-rule revision.
            continue
        }

        # No incubation and no lifecycle work. The only remaining valid state is
        # idle = EXACTLY {.gitkeep}. A corresponding existing rule output must back it.
        $isIdleExact = ($hasGitkeep -and $allowedFileCount -eq 1)
        if ($isIdleExact) {
            $ruleOutputNested = Join-Path -Path (Join-Path -Path $rulesDir -ChildPath $id) -ChildPath ($id + '.md')
            $ruleOutputSnippet = Join-Path -Path (Join-Path -Path $ruleDocsDir -ChildPath '..') -ChildPath ('snippets/rules/' + $id + '.md')
            $ruleOutputSnippet = [System.IO.Path]::GetFullPath($ruleOutputSnippet)
            $hasRuleOutput = (Test-Path -LiteralPath $ruleOutputNested -PathType Leaf) -or (Test-Path -LiteralPath $ruleOutputSnippet -PathType Leaf)
            if (-not $hasRuleOutput) {
                $violations.Add(('RULE_DOCS-ORPHAN FAIL: idle rule_docs/{0}/ (.gitkeep-only) has no corresponding rule output (expected rules/{0}/{0}.md or snippets/rules/{0}.md): {1} (an idle folder is valid only for an EXISTING rule; a discarded candidate or deleted rule must remove its folder)' -f $id, $rel)) | Out-Null
            }
            continue
        }

        # Neither a recognized work state nor an exact idle .gitkeep folder: an empty
        # folder, or one carrying only stray/disallowed files (those are already
        # reported above) with no .gitkeep and no recognized state file. Flag the
        # folder itself so it is not silently accepted.
        $violations.Add(('RULE_DOCS-PURITY FAIL: rule_docs/{0}/ is in no valid state: {1} (must be idle [.gitkeep only, with an existing rule output], candidate incubation [{0}_incubation.md], or active lifecycle work [{0}_design.md/_plan.md/_work_packet.md])' -f $id, $rel)) | Out-Null
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
            $violations.Add(('E3 FAIL: canonical-looking sibling created during incubation: {0} (folder {2}/{1}/ holds an _incubation document; no _design/_plan/_spec sibling is allowed before promotion)' -f $rel, $folder.Name, $folder.BaseRel)) | Out-Null
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
    $baseEsc = [regex]::Escape($folder.BaseRel)
    # The reference must denote the candidate's OWN <base>/<name>/ folder (base = docs or
    # rule_docs). Trailing slash is OPTIONAL (a directory link is commonly written without
    # it, e.g. [x](scopeguard)). To avoid flagging a bare plain-text name mention (allowed thin
    # metadata), the slash-less relative form is honored ONLY in markdown link-target position
    # "](...". and ONLY for a docs-based candidate.
    #   - base-rooted (valid from either README): (./|../)*<base>/<name>  (sub-path / slash / end OK)
    #   - docs-relative link (valid ONLY from docs/README.md, docs candidates only): "](" (./)?<name>
    # Trailing (?![A-Za-z0-9_-]) prevents matching <name> as a prefix of a longer folder name.
    $baseRootedPattern = '(?<![A-Za-z0-9_./\\-])(?:\.{1,2}[/\\])*' + $baseEsc + '[/\\]' + $name + '(?![A-Za-z0-9_-])'
    $docsRelativeLinkPattern = '\]\(\s*<?\s*(?:\.[/\\])?' + $name + '(?![A-Za-z0-9_-])'
    foreach ($readme in $e1ReadmeTargets) {
        if (-not (Test-Path -LiteralPath $readme -PathType Leaf)) { continue }
        $rtext = Read-Utf8 -Path $readme
        $isDocsReadme = ($readme -eq $docsReadme)
        $hit = [regex]::IsMatch($rtext, $baseRootedPattern)
        if ((-not $hit) -and $isDocsReadme -and ($folder.BaseRel -eq 'docs')) { $hit = [regex]::IsMatch($rtext, $docsRelativeLinkPattern) }
        if ($hit) {
            $rel = Resolve-ProjectRelativePath -Path $readme -ProjectRoot $project
            $violations.Add(('E1 FAIL: incubation-only candidate folder is referenced as a discovery/domain target: {0} links/points at {2}/{1}/ (a folder holding only _incubation.md is a non-domain/non-rule candidate container; thin name/owner/review-date metadata is allowed, a discovery link/path is not)' -f $rel, $folder.Name, $folder.BaseRel)) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Line ('scanned ProjectRoot {0}; found {1} incubation candidate folder(s)' -f $project, $incubationFolders.Count)
Write-Line 'SCOPE INFO: MECHANICAL subset only. Scanned: candidate incubation folders in BOTH docs/<candidate>/ (domain candidates) and rule_docs/<candidate>/ (rule candidates); E1 = docs/README.md + rules/README.md must not reference a candidate folder as a discovery target; E2 = all .md under rules/ (recursive, so any package-local templates/ or checklists/ under a rule ARE included) + docs/README.md must not durably reference a candidate *_incubation.md; E3 = no _design/_plan/_spec siblings in a candidate incubation folder (docs/ or rule_docs/); rule_docs structure = each direct child rule_docs/<id>/ is in one of THREE valid states -- idle (.gitkeep only, requires an existing rule output rules/<id>/<id>.md or snippets/rules/<id>.md, else RULE_DOCS-ORPHAN), candidate incubation (<id>_incubation.md), or active lifecycle work (<id>_design.md/_plan.md/_work_packet.md) -- with only .gitkeep or <id>_{incubation,design,plan,work_packet}.md files (RULE_DOCS-FILE otherwise), no subfolders, and no loose top-level files under rule_docs/ (RULE_DOCS-PURITY). E4/E5 are advisory only (not enforced). Any canonical surface outside those exact globs (e.g. repo-root templates/, snippets/ and skills, generator inputs, docs/** other than docs/README.md) is NOT mechanically scanned (manual conformance). A PASS attests only to the scanned subset, not full incubation-tier conformance.'

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
    Write-Line ('FAIL ({0} E1/E2/E3/rule_docs-purity/orphan/file violation(s) in the mechanically-scanned subset)' -f $violations.Count)
    exit 1
}

Write-Line 'PASS (no E1/E2/E3/rule_docs-purity/orphan/file violations in the mechanically-scanned subset)'
exit 0
