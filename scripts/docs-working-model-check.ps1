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

function Test-IsConcretePathRef {
    # Shared path-vs-concept discriminator (single-home; reused by the E2
    # candidate-_incubation scan and reusable by any future durable-pointer scan --
    # do NOT fork a divergent copy). Given a path-shaped token already matched by a
    # caller's regex, decide whether it is a CONCRETE located path rather than a
    # template / concept token:
    #   - an angle-bracket placeholder anywhere (e.g. <candidate>) -> a template
    #     pattern, NOT a concrete path;
    #   - a glob segment ('*' anywhere, e.g. log/**) -> a concept/pattern mention,
    #     NOT a concrete path.
    # The caller's regex is responsible for requiring a real leading directory
    # segment; this helper only rejects the placeholder / glob shapes.
    param([string] $Ref)
    if ($Ref.Contains('<') -or $Ref.Contains('>')) { return $false }
    if ($Ref.Contains('*')) { return $false }
    return $true
}

function Get-PointyBracketLinkDestinations {
    # A markdown link may wrap its destination in angle brackets: [text](<dest>).
    # The wrapped destination itself carries NO angle bracket (a <candidate>
    # placeholder lives INSIDE a path segment -- a different, non-concrete shape).
    # Return the inner destinations so they can be tail-checked like a bare path
    # reference (the main E2 regex's lookbehind intentionally skips a '<'-wrapped
    # destination). CommonMark allows an OPTIONAL link title after the destination
    # (whitespace then a "..."/'...'/(...) title before the closing ')'), so the
    # closing ')' may be separated from '>' by ` "title"`; unwrap those too (the
    # captured dest never includes the title). The dest group stops at '>' so a
    # title never leaks into the returned reference.
    param([string] $Text)
    $dests = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($Text, '\]\(\s*<([^<>\r\n]+)>(?:\s+(?:"[^"\r\n]*"|''[^''\r\n]*''|\([^()\r\n]*\)))?\s*\)')) {
        $dests.Add($m.Groups[1].Value) | Out-Null
    }
    return $dests
}

function Test-CandidateTailMatch {
    # True if a normalized (forward-slash) reference resolves to a discovered
    # candidate file path tail (<candidate-folder>/<candidate-file>), either exactly
    # or as a trailing path segment. (Shared by the bare-reference and the
    # angle-bracket-link E2 scans so the tail logic has a single home.)
    param([string] $NormRef, $Tails)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase
    foreach ($tail in $Tails) {
        if ($NormRef.Equals($tail, $cmp) -or $NormRef.EndsWith('/' + $tail, $cmp)) { return $true }
    }
    return $false
}

function Get-LeadingIdToken {
    # Single-home backlog-id token parser, shared by the BACKLOG-NEXTID per-prefix
    # floor scan and the table-row scan so the two stay symmetric (the asymmetry
    # they used to have -- floors counting every token on the line, rows requiring
    # an EXACT bare "<PREFIX>-NN" first cell -- was the D1/D8 defect). Strip markdown
    # decoration (** / backtick) then match ONLY the LEADING "<PREFIX>-<digits>"
    # token; any trailing parenthetical / prose after the token is ignored (so a
    # "next ID: RV-B-10 (do not reuse RV-B-99)" segment yields RV-B-10, not RV-B-99,
    # and a decorated/annotated row first cell like "**RV-B-20**" or "RV-B-20
    # (retired)" still counts as RV-B-20). The digit run must END at a non-alnum
    # boundary: an UNSEPARATED alnum suffix (e.g. "RV-B-17abc") is a malformed/suffixed
    # id, NOT a token, and yields $null -- distinct from a space/paren-separated trailing
    # token (e.g. "RV-B-20 (retired)"), which is fine; only the UNSEPARATED suffix is
    # rejected. Returns $null when there is no id-shaped
    # leading token. The numeric part is parsed as [long] (overflow-safe; the old
    # [int] cast aborted the whole run under $ErrorActionPreference='Stop' on a value
    # > 2^31); a digit run too large for [long] is reported via .Overflow so the
    # caller emits a clean FAIL rather than crashing.
    param([string] $Text)
    if ($null -eq $Text) { return $null }
    $stripped = $Text -replace '[`*]', ''
    if ($stripped -notmatch '^\s*([A-Za-z]+(?:-[A-Za-z]+)*)-([0-9]+)(?![0-9A-Za-z])') { return $null }
    $prefix = $matches[1]
    $digits = $matches[2]
    $num = [long]0
    $parsed = [System.Int64]::TryParse($digits, [ref] $num)
    return [pscustomobject]@{
        Prefix   = $prefix
        Number   = $num
        Overflow = (-not $parsed)
    }
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
#   rules/**/*.md + rules/README.md + snippets/rules/**/*.md (incl. snippets/rules/README.md)
#   + docs/README.md. snippets/rules/ is a distributed canonical rule tier (the
#   global-distribution rules index + rule bodies), peer to rules/ for E2 purposes,
#   so it is scanned with the SAME E2 discriminator/$incTails matching as rules/.
$canonicalFiles = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $rulesDir -PathType Container) {
    $rulesMd = @(Get-ChildItem -LiteralPath $rulesDir -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)
    foreach ($rf in $rulesMd) { $canonicalFiles.Add($rf.FullName) | Out-Null }
}
$snippetsRulesDir = Join-Path -Path $project -ChildPath 'snippets/rules'
if (Test-Path -LiteralPath $snippetsRulesDir -PathType Container) {
    $snippetsRulesMd = @(Get-ChildItem -LiteralPath $snippetsRulesDir -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)
    foreach ($sf in $snippetsRulesMd) { if (-not ($canonicalFiles -contains $sf.FullName)) { $canonicalFiles.Add($sf.FullName) | Out-Null } }
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
# candidate *_incubation.md. Scan rules/**/*.md + rules/README.md +
# snippets/rules/**/*.md (incl. snippets/rules/README.md) + docs/README.md for a
# path or markdown link that points at a *_incubation.md file. A bare mention of
# the literal token "_incubation" (rule concept) is NOT a violation; only an
# actual path/link to a *_incubation.md file is.
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
# no '<' / '>' in the reference. The leading dir segment may be `.`/`..` relative,
# or an absolute drive-letter / rooted segment (e.g. `C:/.../<name>_incubation.md`);
# the tail-match against discovered candidates still confines a hit to a real
# candidate path.
$incRefPattern = '(?<![A-Za-z0-9_./\\<>-])(?:[A-Za-z]:[/\\])?(?:\.{1,2}[/\\])?(?:[A-Za-z0-9_.\-]+[/\\])+[A-Za-z0-9_.\-]*_incubation\.md'
foreach ($cf in $canonicalFiles) {
    if (-not (Test-Path -LiteralPath $cf -PathType Leaf)) { continue }
    $text = Read-Utf8 -Path $cf
    $m = [regex]::Matches($text, $incRefPattern)
    foreach ($match in $m) {
        # A template/concept token (a <candidate> placeholder, or a glob) is not a
        # concrete located path -> not a durable reference (shared path-vs-concept
        # discriminator). The regex negative lookbehind already blocks a '<'
        # immediately before the match; this also rejects one mid-reference.
        if (-not (Test-IsConcretePathRef -Ref $match.Value)) { continue }
        # Only a reference that resolves to a REAL discovered candidate file PATH
        # (<candidate-folder>/<candidate-file>) is an E2 violation; the same leaf filename in a
        # different / non-existent folder, or an example / historical path, is not.
        $normRef = ($match.Value -replace '\\', '/')
        if (-not (Test-CandidateTailMatch -NormRef $normRef -Tails $incTails)) { continue }
        $rel = Resolve-ProjectRelativePath -Path $cf -ProjectRoot $project
        $violations.Add(('E2 FAIL: canonical surface durably references a candidate _incubation document: {0} -> {1} (a canonical->candidate reference may only be an absorbed-conclusion summary, never a durable path/link)' -f $rel, $match.Value)) | Out-Null
    }
    # Angle-bracket (pointy-bracket) markdown link destinations [text](<dest>): the
    # main scan's negative lookbehind + concrete-path discriminator intentionally
    # skip a '<'-wrapped destination, so unwrap those here and tail-check the inner
    # path the same way -- a durable [x](<.../<cand>_incubation.md>) link is still
    # caught. The inner dest carries no angle bracket (a <candidate> placeholder is a
    # different, non-concrete shape that stays excluded by Test-IsConcretePathRef). A
    # destination may carry an OPTIONAL trailing URL fragment/query after the .md
    # (`..._incubation.md#anchor` / `...?query`); accept that in the end-anchor test and
    # STRIP it before the tail-match so the path portion still resolves to the discovered
    # candidate tail (over-reach stays zero: the tail-match is still confined to a real
    # discovered <candidate-folder>/<file>, so a fragment never manufactures a false hit).
    foreach ($dest in (Get-PointyBracketLinkDestinations -Text $text)) {
        if ($dest -notmatch '_incubation\.md(?:[#?][^>]*)?\s*$') { continue }
        # Strip an optional #fragment / ?query (URL syntax) before the tail-match: the
        # path portion is what resolves to the candidate file path.
        $destPath = ($dest.Trim() -replace '[#?].*$', '')
        if (-not (Test-IsConcretePathRef -Ref $destPath)) { continue }
        $normRef = ($destPath -replace '\\', '/')
        if (-not (Test-CandidateTailMatch -NormRef $normRef -Tails $incTails)) { continue }
        $rel = Resolve-ProjectRelativePath -Path $cf -ProjectRoot $project
        $violations.Add(('E2 FAIL: canonical surface durably references a candidate _incubation document (angle-bracket link): {0} -> {1} (a canonical->candidate reference may only be an absorbed-conclusion summary, never a durable path/link)' -f $rel, $dest)) | Out-Null
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
# EN-2 (mechanical, hard FAIL): every PROMOTED domain Spec docs/<domain>/<domain>_spec.md
# must carry a "## Lifecycle state" section holding EXACTLY ONE bolded lifecycle
# marker -- one of **prelive** / **sync-required** / **live**. Detection keys off
# the BOLDED token, NOT a plain-text mention: the live specs write the marker as a
# bolded "- spec <-> implementation: **live**" line AND mention "sync-required" in
# plain prose in the SAME section -- the plain mention must not be counted (a naive
# substring count would wrongly find two tokens and FAIL a conformant spec). So we
# count occurrences of the bolded forms within the Lifecycle-state section and
# require exactly one. Scope is ONLY docs/<domain>/<domain>_spec.md (folder name ==
# file prefix): an incubation-only candidate (docs/<cand>/ with no <cand>_spec.md)
# is auto-excluded, and a rule has no _spec (a rule is its own spec-of-record) so it
# is not checked here. Violations: no "## Lifecycle state" section / zero bolded
# markers / two-or-more (an invalid bolded token is not one of the three, so it
# counts as zero valid markers and is reported via the count branch).
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $docsDir -PathType Container) {
    $lifecycleMarkerForms = @('**prelive**', '**sync-required**', '**live**')
    foreach ($domainDir in @(Get-ChildItem -LiteralPath $docsDir -Directory -ErrorAction SilentlyContinue)) {
        $domain = $domainDir.Name
        $specPath = Join-Path -Path $domainDir.FullName -ChildPath ($domain + '_spec.md')
        if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) { continue }
        $rel = Resolve-ProjectRelativePath -Path $specPath -ProjectRoot $project
        $specText = Read-Utf8 -Path $specPath
        $specLines = $specText -split "\r?\n"

        # Collect the "## Lifecycle state" section body: every line after the heading
        # up to the next "# " / "## " heading (a deeper "### " heading does not end it).
        # A fenced code block suspends BOTH heading detection (a fenced "## Lifecycle
        # state" line is an example, not a real section) AND marker counting (a fenced
        # **live**/**sync-required**/**prelive** is an illustrative example, not this
        # spec's own marker). Fence tracking is CommonMark-correct: an OPENING fence
        # records its delimiter CHAR (backtick vs tilde) and its LENGTH N (a run of >=3,
        # optionally indented up to 3 spaces, an info string may follow); it is CLOSED
        # ONLY by a later "bare" fence of the SAME char with length >= N (only the
        # delimiter run, optional indent, then trailing whitespace -- no info string). So
        # a tilde line inside a backtick fence, or a 3-char run inside a 4-char fence,
        # does NOT close it. The fence-delimiter lines themselves and every line inside a
        # fence are excluded from the marker-count body, and a fenced heading is not
        # counted as a section. Inline-code handling is intentionally not done (out of
        # scope); only fenced blocks are excluded. Section headings are COUNTED (not
        # stopped at the first): more than one is an EN-2 violation (ambiguous state).
        $sectionHeadingCount = 0
        $inSection = $false
        $inFence   = $false
        $fenceChar = ''
        $fenceLen  = 0
        $sectionLines = New-Object System.Collections.Generic.List[string]
        foreach ($line in $specLines) {
            if (-not $inFence) {
                # Not in a fence: an opening fence is a run of >=3 backticks or tildes,
                # optionally indented up to 3 spaces; record its char + length.
                if ($line -match '^ {0,3}(`{3,}|~{3,})') {
                    $fenceChar = $matches[1].Substring(0, 1)
                    $fenceLen  = $matches[1].Length
                    $inFence   = $true
                    continue
                }
            }
            else {
                # In a fence: a closing fence is a BARE run (no info string) of the SAME
                # char with length >= the opener's, optionally indented up to 3 spaces.
                if ($line -match '^ {0,3}(`{3,}|~{3,})\s*$') {
                    $closeRun = $matches[1]
                    if ($closeRun.Substring(0, 1) -eq $fenceChar -and $closeRun.Length -ge $fenceLen) {
                        $inFence   = $false
                        $fenceChar = ''
                        $fenceLen  = 0
                    }
                }
                # Every line inside the fence (incl. the closing delimiter and any inner
                # different-delimiter line) is skipped: not a heading, markers not counted.
                continue
            }
            if ($line -match '^##\s+Lifecycle state\s*$') {
                $sectionHeadingCount++
                $inSection = $true
                continue
            }
            if ($inSection) {
                if ($line -match '^#{1,2}\s') { $inSection = $false; continue }
                $sectionLines.Add($line) | Out-Null
            }
        }

        if ($sectionHeadingCount -eq 0) {
            $violations.Add(('EN-2 FAIL: promoted domain Spec has no "## Lifecycle state" section: {0} (a promoted <domain>_spec.md must carry a Lifecycle state section with exactly one bolded lifecycle marker: **prelive**/**sync-required**/**live**)' -f $rel)) | Out-Null
            continue
        }
        if ($sectionHeadingCount -gt 1) {
            $violations.Add(('EN-2 FAIL: promoted domain Spec has more than one "## Lifecycle state" section (found {1}, expected exactly one): {0} (duplicate Lifecycle state sections make the lifecycle marker ambiguous; keep a single section)' -f $rel, $sectionHeadingCount)) | Out-Null
            continue
        }

        $sectionText = ($sectionLines -join "`n")
        $markerCount = 0
        foreach ($form in $lifecycleMarkerForms) {
            $markerCount += ([regex]::Matches($sectionText, [regex]::Escape($form))).Count
        }
        if ($markerCount -ne 1) {
            $violations.Add(('EN-2 FAIL: promoted domain Spec "## Lifecycle state" section does not hold exactly one bolded lifecycle marker (found {1}, expected exactly one of **prelive**/**sync-required**/**live**): {0} (the BOLDED marker token must appear once; a plain-prose mention, a fenced-code example, or an invalid bolded token does not count)' -f $rel, $markerCount)) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# DOCS-PURITY (mechanical, hard FAIL): structural purity of a PROMOTED docs domain
# folder -- the docs/ sibling of the rule_docs/ purity check, but TRANSITION-AWARE
# and looser (docs/ also holds in-flight candidates + legacy residue). It binds a
# PROMOTED-ENTRY domain = docs/<domain>/ that carries any one of its own promoted
# lifecycle docs <domain>_{design,plan,spec}.md. A candidate in incubation can only
# carry <domain>_incubation.md (E3 forbids a _design/_plan/_spec sibling before
# promotion), so the presence of any _design/_plan/_spec necessarily marks a domain
# that has ENTERED promotion (mid-promotion binding) -- the false-positive set against
# an in-flight candidate is empty. An in-flight candidate (docs/<cand>/ with an
# _incubation.md and no _design/_plan/_spec) or legacy residue (none of the three) is
# NOT bound -> conform-pass (transition-aware; matches the rule's *Stable filename
# rule* end-state model). For a bound promoted domain the *Stable filename rule*
# forbids: a filename-evading subfolder (e.g. docs/<domain>/work/ -- any subfolder)
# and a non-role file -- a <topic>_*.md topic-named file (a .md whose prefix is not
# the domain name) or any <domain>_*.md that is not an allowed role. Allowed:
# README.md, the domain-prefixed lifecycle role files
# <domain>_{spec,backlog,design,plan,work_packet,incubation}.md, AND the auxiliary
# role docs <domain>_{policy,contract,state,status,guide}.md. The auxiliary roles are
# *deferred* (introduced only by an explicit Design/Plan decision -- *Stable filename
# rule*), but this check cannot verify that an approval exists (not a structural
# fact); rather than over-strictly forbid an approved auxiliary doc it ACCEPTS the
# known auxiliary role names (.md only). Anything else is a DOCS-PURITY violation.
# STRUCTURE (snapshot) check only -- deletes nothing.
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $docsDir -PathType Container) {
    foreach ($domainDir in @(Get-ChildItem -LiteralPath $docsDir -Directory -ErrorAction SilentlyContinue)) {
        $domain = $domainDir.Name
        # Promotion-entry discriminator: bound iff any one of _design/_plan/_spec is present.
        $isPromotedEntry = $false
        foreach ($role in @('_design.md', '_plan.md', '_spec.md')) {
            if (Test-Path -LiteralPath (Join-Path -Path $domainDir.FullName -ChildPath ($domain + $role)) -PathType Leaf) { $isPromotedEntry = $true; break }
        }
        if (-not $isPromotedEntry) { continue }  # not promoted -> conform-pass (in-flight candidate / legacy)

        $allowedDocsNames = @(
            'README.md',
            ($domain + '_spec.md'),
            ($domain + '_backlog.md'),
            ($domain + '_design.md'),
            ($domain + '_plan.md'),
            ($domain + '_work_packet.md'),
            ($domain + '_incubation.md'),
            ($domain + '_policy.md'),
            ($domain + '_contract.md'),
            ($domain + '_state.md'),
            ($domain + '_status.md'),
            ($domain + '_guide.md'))
        $cmpDocs = [System.StringComparison]::OrdinalIgnoreCase
        foreach ($entry in @(Get-ChildItem -LiteralPath $domainDir.FullName -Force -ErrorAction SilentlyContinue)) {
            $entryRel = Resolve-ProjectRelativePath -Path $entry.FullName -ProjectRoot $project
            if ($entry.PSIsContainer) {
                $violations.Add(('DOCS-PURITY FAIL: disallowed subfolder under promoted docs domain docs/{0}/: {1} (a promoted domain folder holds only README.md or {0}_{{spec,backlog,design,plan,work_packet,incubation,policy,contract,state,status,guide}}.md; a filename-evading subfolder such as docs/{0}/work/ is forbidden by the Stable filename rule)' -f $domain, $entryRel)) | Out-Null
                continue
            }
            $isAllowed = $false
            foreach ($an in $allowedDocsNames) {
                if ([string]::Equals($entry.Name, $an, $cmpDocs)) { $isAllowed = $true; break }
            }
            if (-not $isAllowed) {
                $violations.Add(('DOCS-PURITY FAIL: disallowed file under promoted docs domain docs/{0}/: {1} (allowed: README.md or {0}_{{spec,backlog,design,plan,work_packet,incubation,policy,contract,state,status,guide}}.md, .md only; a <topic>_*.md topic-named file or any non-role {0}_*.md is forbidden by the Stable filename rule)' -f $domain, $entryRel)) | Out-Null
            }
        }
    }
}

# ---------------------------------------------------------------------------
# BACKLOG-NEXTID (mechanical, hard FAIL): a domain future-work queue
# docs/<domain>/<domain>_backlog.md must carry a "next ID:" header whose per-prefix
# floor is strictly ABOVE every present row id of that prefix (ID-reuse prevention --
# docs-working-model *Future-work queue*). The header may list one OR several
# per-prefix floors separated by middots (the real install-update backlog carries
# two: IU-B / IU-D). The floor and the row scan use the SAME leading-token parser
# (Get-LeadingIdToken) so they stay symmetric:
#   - FLOOR = the DECLARED leading "<PREFIX>-<digits>" token of EACH middot-separated
#     segment of the next-ID line; a parenthetical / prose token AFTER the declared
#     token (e.g. "next ID: RV-B-10 (do not reuse RV-B-99)" -> floor RV-B-10) does
#     NOT inflate the floor, and a glob like "IU-B-*" carries no digits so it is not
#     a floor.
#   - ROW = the FIRST table cell's leading "<PREFIX>-<digits>" token AFTER stripping
#     markdown decoration (** / backtick) and ignoring any trailing parenthetical, so
#     a decorated / annotated id ("**RV-B-20**", "RV-B-20 (retired)") still counts.
# This generalizes the rule's single-prefix illustration to the real multi-prefix
# shape -- no rule-text change. Violations: a "next ID:" header that holds ZERO valid
# "<PREFIX>-NN" tokens (malformed header -- rule's required header form); a prefix
# that has rows but no next-ID floor; a floor that is not strictly greater than that
# prefix's max present row id; or an id whose digit run overflows [long] (reported as
# a clean malformed-id FAIL, never a crash). (Reuse of an id below a deleted-row gap
# is NOT detected -- a deliberate NSE limit; this is a floor check, not full
# monotonicity.)
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $docsDir -PathType Container) {
    foreach ($domainDir in @(Get-ChildItem -LiteralPath $docsDir -Directory -ErrorAction SilentlyContinue)) {
        $domain = $domainDir.Name
        $backlogPath = Join-Path -Path $domainDir.FullName -ChildPath ($domain + '_backlog.md')
        if (-not (Test-Path -LiteralPath $backlogPath -PathType Leaf)) { continue }
        $rel = Resolve-ProjectRelativePath -Path $backlogPath -ProjectRoot $project
        $backlogText = Read-Utf8 -Path $backlogPath
        $backlogLines = $backlogText -split "\r?\n"

        # Per-prefix floors from the (first) "next ID:" line.
        $nextIdLine = $null
        foreach ($line in $backlogLines) {
            if ($line -match '^\s*next ID:') { $nextIdLine = $line; break }
        }
        if ($null -eq $nextIdLine) {
            $violations.Add(('BACKLOG-NEXTID FAIL: domain backlog has no "next ID:" header line: {0} (a future-work queue must carry one "next ID: <PREFIX>-NN" header line for ID-reuse prevention)' -f $rel)) | Out-Null
            continue
        }
        # The declared floor of each middot-separated segment is its LEADING id token
        # only (a trailing parenthetical / prose token does not inflate the floor).
        $afterLabel = ($nextIdLine -replace '^\s*next ID:\s*', '')
        $floors = @{}
        $floorMalformed = $false
        foreach ($seg in ($afterLabel -split ([string][char]0x00B7))) {
            $tok = Get-LeadingIdToken -Text $seg
            if ($null -eq $tok) { continue }
            if ($tok.Overflow) {
                $violations.Add(('BACKLOG-NEXTID FAIL: domain backlog next-ID floor id number is too large to parse: {0} (id "{1}-..." overflows a 64-bit integer; use a sane sequential id)' -f $rel, $tok.Prefix)) | Out-Null
                $floorMalformed = $true
                continue
            }
            if ((-not $floors.ContainsKey($tok.Prefix)) -or ($tok.Number -gt $floors[$tok.Prefix])) { $floors[$tok.Prefix] = $tok.Number }
        }
        if (($floors.Count -eq 0) -and (-not $floorMalformed)) {
            $violations.Add(('BACKLOG-NEXTID FAIL: domain backlog "next ID:" header holds no valid "<PREFIX>-NN" token: {0} (the header is present but malformed; it must declare at least one "next ID: <PREFIX>-NN" floor)' -f $rel)) | Out-Null
            continue
        }

        # Per-prefix max present row id (first table cell's leading id token).
        $rowMax = @{}
        $rowOverflow = $false
        foreach ($line in $backlogLines) {
            if ($line -notmatch '^\s*\|') { continue }
            $cells = $line.Split('|')
            if ($cells.Count -lt 2) { continue }
            $tok = Get-LeadingIdToken -Text $cells[1]
            if ($null -eq $tok) { continue }
            if ($tok.Overflow) {
                $violations.Add(('BACKLOG-NEXTID FAIL: domain backlog row id number is too large to parse: {0} (id "{1}-..." overflows a 64-bit integer; use a sane sequential id)' -f $rel, $tok.Prefix)) | Out-Null
                $rowOverflow = $true
                continue
            }
            if ((-not $rowMax.ContainsKey($tok.Prefix)) -or ($tok.Number -gt $rowMax[$tok.Prefix])) { $rowMax[$tok.Prefix] = $tok.Number }
        }
        if ($rowOverflow) { continue }

        foreach ($rp in $rowMax.Keys) {
            if (-not $floors.ContainsKey($rp)) {
                $violations.Add(('BACKLOG-NEXTID FAIL: domain backlog has rows with prefix {1} but no matching next-ID floor: {0} (each row-id prefix must be tracked by a "next ID: {1}-NN" floor)' -f $rel, $rp)) | Out-Null
                continue
            }
            if ($floors[$rp] -le $rowMax[$rp]) {
                $violations.Add(('BACKLOG-NEXTID FAIL: domain backlog next-ID floor {1}-{2} is not above the max present {1} row id {1}-{3}: {0} (next ID must be strictly greater than every present row id of that prefix; id reuse/regression is forbidden)' -f $rel, $rp, $floors[$rp], $rowMax[$rp])) | Out-Null
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Line ('scanned ProjectRoot {0}; found {1} incubation candidate folder(s)' -f $project, $incubationFolders.Count)
Write-Line 'SCOPE INFO: MECHANICAL subset only. Scanned: candidate incubation folders in BOTH docs/<candidate>/ (domain candidates) and rule_docs/<candidate>/ (rule candidates); E1 = docs/README.md + rules/README.md must not reference a candidate folder as a discovery target; E2 = all .md under rules/ (recursive, so any package-local templates/ or checklists/ under a rule ARE included) + all .md under snippets/rules/ (recursive, incl. snippets/rules/README.md) + docs/README.md must not durably reference a candidate *_incubation.md; E3 = no _design/_plan/_spec siblings in a candidate incubation folder (docs/ or rule_docs/); EN-2 = every promoted domain Spec docs/<domain>/<domain>_spec.md must carry a ## Lifecycle state section with exactly one bolded lifecycle marker (**prelive**/**sync-required**/**live**); DOCS-PURITY = every PROMOTED docs domain (docs/<domain>/ carrying any one of <domain>_{design,plan,spec}.md -- promotion-entry; an in-flight candidate or legacy residue with none of the three is conform-pass) holds only README.md or <domain>_{spec,backlog,design,plan,work_packet,incubation,policy,contract,state,status,guide}.md with no subfolders (a <topic>_*.md topic file or any non-role <domain>_*.md or a docs/<domain>/work/ subfolder is forbidden; the auxiliary role docs <domain>_{policy,contract,state,status,guide}.md are ACCEPTED -- their Design/Plan approval is not a structural fact this check can verify, so it does not over-strictly forbid them); BACKLOG-NEXTID = every domain backlog docs/<domain>/<domain>_backlog.md carries a next-ID header (present-but-zero-valid-token = malformed FAIL) whose per-prefix floor (each middot-separated segment''s leading declared <PREFIX>-NN token, prose parentheticals excluded) is strictly above every present table-row id of that prefix (a decorated/annotated row id such as **PFX-NN** or PFX-NN (retired) still counts); rule_docs structure = each direct child rule_docs/<id>/ is in one of THREE valid states -- idle (.gitkeep only, requires an existing rule output rules/<id>/<id>.md or snippets/rules/<id>.md, else RULE_DOCS-ORPHAN), candidate incubation (<id>_incubation.md), or active lifecycle work (<id>_design.md/_plan.md/_work_packet.md) -- with only .gitkeep or <id>_{incubation,design,plan,work_packet}.md files (RULE_DOCS-FILE otherwise), no subfolders, and no loose top-level files under rule_docs/ (RULE_DOCS-PURITY). E4/E5 are advisory only (not enforced). snippets/rules/ IS now mechanically scanned for E2 (it is no longer an unscanned tier). Any canonical surface outside those exact globs (e.g. repo-root templates/, snippets/ outside snippets/rules/, skills, generator inputs, docs/** other than docs/README.md and the promoted-Spec Lifecycle-state check) is NOT mechanically scanned (manual conformance). KNOWN MECHANICAL RESIDUALS (disclosed, not defects): BACKLOG-NEXTID generalizes the rule''s single-prefix "next ID: <PREFIX>-NN" wording to the real multi-prefix per-prefix-floor shape by design (no rule-text change), and a deleted-row-gap reuse below the floor is intentionally not detected (floor check, not full monotonicity). E2 durable-reference detection covers the common forms (a markdown link [x](dest) or [x](<dest>) including an optional CommonMark title and an optional trailing #fragment / ?query on the destination, a bare relative / . / .. path, and a drive-letter absolute) but NOT every theoretical shape: a POSIX-rooted absolute /work/.../<cand>_incubation.md, a bare autolink <...>, and a reference-style [ref]: <...> link definition are narrow unscanned residuals (manual conformance); and a hit is confined to a discovered <candidate-folder>/<file> tail, so a bare-leaf <cand>_incubation.md with no concrete folder is intentionally not flagged. A PASS attests only to the scanned subset, not full incubation-tier conformance.'

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
    Write-Line ('FAIL ({0} E1/E2/E3/EN-2/DOCS-PURITY/BACKLOG-NEXTID/rule_docs-purity/orphan/file violation(s) in the mechanically-scanned subset)' -f $violations.Count)
    exit 1
}

Write-Line 'PASS (no E1/E2/E3/EN-2/DOCS-PURITY/BACKLOG-NEXTID/rule_docs-purity/orphan/file violations in the mechanically-scanned subset)'
exit 0
