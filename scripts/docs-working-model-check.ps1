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
$diagnosticInfos = New-Object System.Collections.Generic.List[string]

$docsDir = Join-Path -Path $project -ChildPath 'docs'
$rulesDir = Join-Path -Path $project -ChildPath 'rules'
$docsReadme = Join-Path -Path $docsDir -ChildPath 'README.md'
$rulesReadme = Join-Path -Path $rulesDir -ChildPath 'README.md'

# Discover candidate incubation folders. The Incubation (pre-promotion) section
# defines two candidate homes (a domain OR a rule candidate):
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
# rule_docs structural diagnostic. Direct children remain owner-local planning
# homes. Loose top-level files, subfolders, mixed-owner/non-.md files, candidate
# backlogs without a rule, and orphan authority are deterministic failures when
# this checker is invoked. The familiar role names are defaults, not a closed
# universe: an additional <id>_*.md role is reported as INFO so its Design/Plan
# admission remains a semantic lifecycle judgment.
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $ruleDocsDir -PathType Container) {
    foreach ($child in @(Get-ChildItem -LiteralPath $ruleDocsDir -Force -ErrorAction SilentlyContinue)) {
        $rel = Resolve-ProjectRelativePath -Path $child.FullName -ProjectRoot $project
        if (-not $child.PSIsContainer) {
            $violations.Add(('RULE_DOCS-PURITY FAIL: loose file directly under rule_docs/: {0} (rule_docs holds per-rule folders rule_docs/<id>/; a top-level file has no rule owner)' -f $rel)) | Out-Null
            continue
        }

        $id = $child.Name
        $cmp = [System.StringComparison]::OrdinalIgnoreCase

        $entries = @(Get-ChildItem -LiteralPath $child.FullName -Force -ErrorAction SilentlyContinue)
        $hasLifecycle = $false
        $hasGitkeep    = $false
        $hasBacklog    = $false
        $sameOwnerAuxCount = 0
        foreach ($entry in $entries) {
            $entryRel = Resolve-ProjectRelativePath -Path $entry.FullName -ProjectRoot $project
            if ($entry.PSIsContainer) {
                $violations.Add(('RULE_DOCS-FILE FAIL: disallowed subfolder under rule_docs/{0}/: {1} (a subfolder can hide lifecycle or split one rule owner across physical homes)' -f $id, $entryRel)) | Out-Null
                continue
            }

            if ([string]::Equals($entry.Name, '.gitkeep', $cmp)) {
                $hasGitkeep = $true
                continue
            }

            if ((-not $entry.Name.EndsWith('.md', $cmp)) -or
                (-not $entry.Name.StartsWith(($id + '_'), $cmp))) {
                $violations.Add(('RULE_DOCS-FILE FAIL: mixed-owner or non-.md file under rule_docs/{0}/: {1} (a role file must be {0}_*.md; README.md and another owner prefix are not rule-local roles)' -f $id, $entryRel)) | Out-Null
                continue
            }

            if ([string]::Equals($entry.Name, ($id + '_incubation.md'), $cmp)) {
                # Candidate state is already discovered by the shared E1-E3
                # incubation scan. No separate rule_docs hard check is attached
                # to the incubation filename here.
            } elseif ([string]::Equals($entry.Name, ($id + '_backlog.md'), $cmp)) {
                $hasBacklog = $true
            } elseif ([string]::Equals($entry.Name, ($id + '_design.md'), $cmp) -or
                [string]::Equals($entry.Name, ($id + '_plan.md'), $cmp) -or
                [string]::Equals($entry.Name, ($id + '_work_packet.md'), $cmp)) {
                $hasLifecycle = $true
            } else {
                $sameOwnerAuxCount++
                $diagnosticInfos.Add(('RULE_DOCS-ROLE INFO: same-owner non-default role found under rule_docs/{0}/: {1} (default roles are {0}_{{incubation,design,plan,work_packet,backlog}}.md; admission of another {0}_*.md role is a Design/Plan judgment, not a closed-set violation)' -f $id, $entryRel)) | Out-Null
            }
        }

        # rule output presence -- THREE forms, because "one file per rule" covers every
        # rules tier: a repo-only rule in PACKAGE form (rules/<id>/<id>.md, e.g.
        # rules/docs-working-model/docs-working-model.md) OR in FLAT form (rules/<id>.md,
        # the flat repo-only rules tier, e.g. rules/powershell-and-file-encoding.md /
        # rules/terminology-glossary.md), OR a global-distribution rule
        # (snippets/rules/<id>.md). Computed ONCE here and shared by the state-independent
        # backlog guard and the idle orphan check below (both invariants are "this folder
        # must map to an EXISTING rule"); recognizing the flat form keeps a flat rule's
        # rule_docs/<id>/ idle folder or backlog from being falsely orphaned / flagged.
        $ruleOutputNested = Join-Path -Path (Join-Path -Path $rulesDir -ChildPath $id) -ChildPath ($id + '.md')
        $ruleOutputFlat = Join-Path -Path $rulesDir -ChildPath ($id + '.md')
        $ruleOutputSnippet = Join-Path -Path (Join-Path -Path $ruleDocsDir -ChildPath '..') -ChildPath ('snippets/rules/' + $id + '.md')
        $ruleOutputSnippet = [System.IO.Path]::GetFullPath($ruleOutputSnippet)
        $hasRuleOutput = (Test-Path -LiteralPath $ruleOutputNested -PathType Leaf) -or (Test-Path -LiteralPath $ruleOutputFlat -PathType Leaf) -or (Test-Path -LiteralPath $ruleOutputSnippet -PathType Leaf)

        # A rule backlog is the queue of an existing rule. This diagnostic checks
        # only the presence of one of the three terminal rule-output shapes.
        if ($hasBacklog -and (-not $hasRuleOutput)) {
            $violations.Add(('RULE_DOCS-CANDIDATE-BACKLOG FAIL: rule_docs/{0}/ carries an {0}_backlog.md but has no corresponding rule output (expected rules/{0}/{0}.md, rules/{0}.md, or snippets/rules/{0}.md): {1} (a rule backlog is the future-work queue of an EXISTING rule; a candidate in incubation or a promoted candidate before its terminal rule lands must keep deferred questions in its _design/_plan, not a backlog)' -f $id, $rel)) | Out-Null
        }

        # Reuse the shared E1-E3 discovery result to distinguish a candidate from
        # an orphan folder. Incubation-specific sibling enforcement remains E3;
        # this rule_docs structural block adds no separate Work-Packet policy.
        if (@($incubationFolders | Where-Object {
                    [string]::Equals($_.FullName, $child.FullName, $cmp)
                }).Count -gt 0) {
            continue
        }

        if ($hasLifecycle) {
            # Active Design/Plan/Work-Packet work can precede terminal rule landing.
            continue
        }

        # Without incubation or active lifecycle work, the folder must belong to an
        # existing terminal rule. .gitkeep and the default role set are conventions,
        # so backlog-only or a same-owner auxiliary role is not independently blocked.
        if (-not $hasRuleOutput) {
            $violations.Add(('RULE_DOCS-ORPHAN FAIL: rule_docs/{0}/ has no incubation or active lifecycle work and no corresponding rule output (expected rules/{0}/{0}.md, rules/{0}.md, or snippets/rules/{0}.md): {1} (the folder would otherwise claim orphan rule authority)' -f $id, $rel)) | Out-Null
        } elseif ((-not $hasGitkeep) -and (-not $hasBacklog) -and ($sameOwnerAuxCount -eq 0)) {
            $diagnosticInfos.Add(('RULE_DOCS-STATE INFO: existing rule_docs/{0}/ has no default role file or .gitkeep anchor: {1} (default-shape diagnostic only)' -f $id, $rel)) | Out-Null
        }
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
# E3 deterministic diagnostic: no canonical-looking sibling in an incubation
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
# E2 deterministic diagnostic: canonical surfaces must not durably reference a
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
        $violations.Add(('E2 FAIL: canonical surface durably references a candidate _incubation document: {0} -> {1} (a canonical->candidate document-level reference is admissible only as an absorbed-conclusion summary, never a durable path/link; a name-identity mention is separately governed by the Promoted-artifact sibling reference clause)' -f $rel, $match.Value)) | Out-Null
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
        $violations.Add(('E2 FAIL: canonical surface durably references a candidate _incubation document (angle-bracket link): {0} -> {1} (a canonical->candidate document-level reference is admissible only as an absorbed-conclusion summary, never a durable path/link; a name-identity mention is separately governed by the Promoted-artifact sibling reference clause)' -f $rel, $dest)) | Out-Null
    }
}

# ---------------------------------------------------------------------------
# SIBLING-MENTION (advisory INFO -- never FAILs, never gates the exit code): an
# inventory of bare NAME-IDENTITY mentions of each DISCOVERED candidate id across
# the SAME canonical-file set the E2 scan reads. Purpose: a mechanical find-step
# aid for the rule's life-event sweeps (Candidate lifecycle promotion / discard;
# State migration -- De-promotion) and for reviewing the Promoted-artifact
# sibling reference form. Whether a mention is status-honest is a semantic
# judgment this check cannot make (a deterministic FAIL here
# would false-positive on legitimate mentions, e.g. the rule's own transition
# clause and legitimate candidate-name mentions), so this stays
# a listing: NOT a violation, NOT a discovery index. Token match: the candidate
# id as a standalone token (boundary excludes [A-Za-z0-9_-] on both sides, so a
# longer slug does not match); path-shaped occurrences are listed too (the
# path-vs-name violation judgment belongs to the E1/E2 scans, which run
# separately and are unchanged by this inventory).
# ---------------------------------------------------------------------------
$siblingMentionInfos = New-Object System.Collections.Generic.List[string]
foreach ($folder in $incubationFolders) {
    $idPattern = '(?<![A-Za-z0-9_-])' + [regex]::Escape($folder.Name) + '(?![A-Za-z0-9_-])'
    foreach ($cf in $canonicalFiles) {
        if (-not (Test-Path -LiteralPath $cf -PathType Leaf)) { continue }
        $cfLines = (Read-Utf8 -Path $cf) -split "\r?\n"
        $hitLines = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $cfLines.Count; $i++) {
            if ([regex]::IsMatch($cfLines[$i], $idPattern)) { $hitLines.Add([string]($i + 1)) | Out-Null }
        }
        if ($hitLines.Count -gt 0) {
            $rel = Resolve-ProjectRelativePath -Path $cf -ProjectRoot $project
            $siblingMentionInfos.Add(('SIBLING-MENTION INFO: candidate "{0}" name-mention(s) on canonical surface {1} line(s) {2} (advisory inventory only; whether the mention falsely claims authority is a semantic judgment)' -f $folder.Name, $rel, ($hitLines -join ','))) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# E1 deterministic diagnostic: a docs/<candidate>/ that holds ONLY _incubation
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
# EN-2 deterministic diagnostic: every PROMOTED domain Spec docs/<domain>/<domain>_spec.md
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
# SPEC-TEMPLATE-SCHEMA deterministic diagnostic. The package template presents
# the eight Spec meaning areas as an authoring default. Missing, extra, or
# duplicated level-2 headings are INFO diagnostics, not independent lifecycle
# blockers. The template must still offer all three lifecycle markers because
# marker meaning is a direct dependency of the rule and produced-Spec contract.
#
# This is TEMPLATE-PATH-ONLY and deliberately does NOT overlap EN-2: EN-2
# validates a PRODUCED domain Spec docs/<domain>/<domain>_spec.md for EXACTLY
# ONE lifecycle marker; this check binds only the template file, requires ALL
# THREE markers (the template offers all three choices), and never scans
# docs/**. A missing template still fails when the rule package exists because
# the package lists the template as a direct form dependency.
# ---------------------------------------------------------------------------
$specTemplatePath = Join-Path -Path $rulesDir -ChildPath 'docs-working-model/templates/docs-working-model_spec_template.md'
$dwmRulePath = Join-Path -Path $rulesDir -ChildPath 'docs-working-model/docs-working-model.md'
if (Test-Path -LiteralPath $specTemplatePath -PathType Leaf) {
    $stRel = Resolve-ProjectRelativePath -Path $specTemplatePath -ProjectRoot $project
    $stText = Read-Utf8 -Path $specTemplatePath
    $stLines = $stText -split "\r?\n"
    # The eight default Spec meaning-area headings, each matched as a
    # "## <heading>" line (a deeper "### " or a "# " level does not count).
    $stRequiredHeadings = @(
        'Header',
        '목표 상태',
        'Owner surface 지도',
        'Durable boundary',
        'Cross-domain interface',
        'Validation expectation',
        'Review focus',
        'Lifecycle state')
    $stHeadingList = ($stRequiredHeadings -join ' / ')
    foreach ($stHeading in $stRequiredHeadings) {
        $stHeadingPattern = '^##\s+' + [regex]::Escape($stHeading) + '\s*$'
        $stFound = $false
        foreach ($stLine in $stLines) {
            if ($stLine -match $stHeadingPattern) { $stFound = $true; break }
        }
        if (-not $stFound) {
            $diagnosticInfos.Add(('SPEC-TEMPLATE-SCHEMA INFO: spec template is missing the default meaning-area heading "## {1}": {0} (the eight-heading shape is an authoring diagnostic, not an independent lifecycle blocker; defaults: {2})' -f $stRel, $stHeading, $stHeadingList)) | Out-Null
        }
    }
    # Heading-shape diagnostics. Collect every LEVEL-2 heading only --
    # the pattern "^##\s+" requires whitespace immediately after exactly two
    # hashes, so a "### " level-3 subheading (a '#' sits where whitespace is
    # required) and a "# " level-1 title (only one hash) are BOTH excluded.
    $stHeadingCounts = [ordered]@{}
    foreach ($stScanLine in $stLines) {
        if ($stScanLine -match '^##\s+(.+?)\s*$') {
            $stHeadingText = $matches[1]
            if ($stHeadingCounts.Contains($stHeadingText)) {
                $stHeadingCounts[$stHeadingText] = [int]$stHeadingCounts[$stHeadingText] + 1
            } else {
                $stHeadingCounts[$stHeadingText] = 1
            }
        }
    }
    foreach ($stSeenHeading in @($stHeadingCounts.Keys)) {
        if ($stRequiredHeadings -notcontains $stSeenHeading) {
            $diagnosticInfos.Add(('SPEC-TEMPLATE-SCHEMA INFO: spec template has a non-default top-level "## {1}" section: {0} (the eight-heading shape is an authoring diagnostic, not a closed schema)' -f $stRel, $stSeenHeading)) | Out-Null
        } elseif ([int]$stHeadingCounts[$stSeenHeading] -gt 1) {
            $diagnosticInfos.Add(('SPEC-TEMPLATE-SCHEMA INFO: spec template has a duplicated default top-level "## {1}" section: {0} (review whether the duplicate hides conflicting meaning; heading count alone is not a lifecycle blocker)' -f $stRel, $stSeenHeading)) | Out-Null
        }
    }
    # The three bolded lifecycle markers (single-home: the same *Spec identity*
    # enumeration + *Spec / rule ↔ implementation synchronization*). Presence anywhere in the template is
    # required (a template offers all three); EN-2's exactly-one rule is for a
    # produced Spec, not for the template.
    $stRequiredMarkers = @('**prelive**', '**sync-required**', '**live**')
    foreach ($stMarker in $stRequiredMarkers) {
        if (-not $stText.Contains($stMarker)) {
            $violations.Add(('SPEC-TEMPLATE-SCHEMA FAIL: spec template is missing the required bolded lifecycle marker "{1}" (present anywhere in the template): {0} (the docs-working-model spec template must carry all three bolded lifecycle markers **prelive** / **sync-required** / **live**)' -f $stRel, $stMarker)) | Out-Null
        }
    }
} elseif (Test-Path -LiteralPath $dwmRulePath -PathType Leaf) {
    # Rule present, direct package form absent. When the rule is absent, a
    # synthetic ProjectRoot has no docs-working-model package to validate.
    $stRel = Resolve-ProjectRelativePath -Path $specTemplatePath -ProjectRoot $project
    $violations.Add(('SPEC-TEMPLATE-SCHEMA FAIL: required spec template is missing while the docs-working-model rule is present: {0}' -f $stRel)) | Out-Null
}

# ---------------------------------------------------------------------------
# DOCS-PURITY deterministic diagnostic for promoted-entry domain folders. A
# subfolder or mixed-owner/non-.md file is a failure because it can split one
# domain owner or hide lifecycle work. README.md and <domain>_*.md are accepted.
# Familiar role names are defaults; another same-owner role emits INFO so its
# Design/Plan admission remains a semantic judgment rather than a closed-set
# checker decision. Incubation-only and legacy folders remain outside this scan.
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

        $defaultDocsNames = @(
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
                $violations.Add(('DOCS-PURITY FAIL: disallowed subfolder under promoted docs domain docs/{0}/: {1} (a subfolder can hide lifecycle or split one domain owner across physical homes)' -f $domain, $entryRel)) | Out-Null
                continue
            }

            if ([string]::Equals($entry.Name, 'README.md', $cmpDocs)) { continue }
            if ((-not $entry.Name.EndsWith('.md', $cmpDocs)) -or
                (-not $entry.Name.StartsWith(($domain + '_'), $cmpDocs))) {
                $violations.Add(('DOCS-PURITY FAIL: mixed-owner or non-.md file under promoted docs domain docs/{0}/: {1} (a role file must be {0}_*.md; topic files with another prefix do not have this domain owner)' -f $domain, $entryRel)) | Out-Null
                continue
            }

            $isDefault = $false
            foreach ($an in $defaultDocsNames) {
                if ([string]::Equals($entry.Name, $an, $cmpDocs)) { $isDefault = $true; break }
            }
            if (-not $isDefault) {
                $diagnosticInfos.Add(('DOCS-ROLE INFO: same-owner non-default role found under docs/{0}/: {1} (default roles are diagnostic conventions; admission of another {0}_*.md role is a Design/Plan judgment)' -f $domain, $entryRel)) | Out-Null
            }
        }
    }
}

# ---------------------------------------------------------------------------
# BACKLOG-NEXTID deterministic floor diagnostic: every future-work queue -- a per-domain
# backlog docs/<domain>/<domain>_backlog.md AND a per-rule backlog
# rule_docs/<id>/<id>_backlog.md -- must carry a "next ID:" header whose per-prefix
# floor is strictly ABOVE every present row id of that prefix (ID-reuse prevention --
# docs-working-model *Future-work queue*; the rule-level backlog reuses the same
# one-line + next-ID-floor form, so the SAME validation binds both trees). The header
# may list one OR several
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
# Collect every future-work queue file to validate: a per-domain backlog
# docs/<domain>/<domain>_backlog.md AND a per-rule backlog
# rule_docs/<id>/<id>_backlog.md (docs-working-model *Future-work queue* -- the
# rule-level backlog reuses the same one-line + next-ID-floor form, so the SAME
# BACKLOG-NEXTID validation binds both trees).
$backlogFiles = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $docsDir -PathType Container) {
    foreach ($domainDir in @(Get-ChildItem -LiteralPath $docsDir -Directory -ErrorAction SilentlyContinue)) {
        $p = Join-Path -Path $domainDir.FullName -ChildPath ($domainDir.Name + '_backlog.md')
        if (Test-Path -LiteralPath $p -PathType Leaf) { $backlogFiles.Add($p) | Out-Null }
    }
}
if (Test-Path -LiteralPath $ruleDocsDir -PathType Container) {
    foreach ($ruleDir in @(Get-ChildItem -LiteralPath $ruleDocsDir -Directory -ErrorAction SilentlyContinue)) {
        $p = Join-Path -Path $ruleDir.FullName -ChildPath ($ruleDir.Name + '_backlog.md')
        if (Test-Path -LiteralPath $p -PathType Leaf) { $backlogFiles.Add($p) | Out-Null }
    }
}
foreach ($backlogPath in $backlogFiles) {
        $rel = Resolve-ProjectRelativePath -Path $backlogPath -ProjectRoot $project
        $backlogText = Read-Utf8 -Path $backlogPath
        $backlogLines = $backlogText -split "\r?\n"

        # Per-prefix floors from the (first) "next ID:" line.
        $nextIdLine = $null
        foreach ($line in $backlogLines) {
            if ($line -match '^\s*next ID:') { $nextIdLine = $line; break }
        }
        if ($null -eq $nextIdLine) {
            $violations.Add(('BACKLOG-NEXTID FAIL: backlog has no "next ID:" header line: {0} (a future-work queue must carry one "next ID: <PREFIX>-NN" header line for ID-reuse prevention)' -f $rel)) | Out-Null
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
                $violations.Add(('BACKLOG-NEXTID FAIL: backlog next-ID floor id number is too large to parse: {0} (id "{1}-..." overflows a 64-bit integer; use a sane sequential id)' -f $rel, $tok.Prefix)) | Out-Null
                $floorMalformed = $true
                continue
            }
            if ((-not $floors.ContainsKey($tok.Prefix)) -or ($tok.Number -gt $floors[$tok.Prefix])) { $floors[$tok.Prefix] = $tok.Number }
        }
        if (($floors.Count -eq 0) -and (-not $floorMalformed)) {
            $violations.Add(('BACKLOG-NEXTID FAIL: backlog "next ID:" header holds no valid "<PREFIX>-NN" token: {0} (the header is present but malformed; it must declare at least one "next ID: <PREFIX>-NN" floor)' -f $rel)) | Out-Null
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
                $violations.Add(('BACKLOG-NEXTID FAIL: backlog row id number is too large to parse: {0} (id "{1}-..." overflows a 64-bit integer; use a sane sequential id)' -f $rel, $tok.Prefix)) | Out-Null
                $rowOverflow = $true
                continue
            }
            if ((-not $rowMax.ContainsKey($tok.Prefix)) -or ($tok.Number -gt $rowMax[$tok.Prefix])) { $rowMax[$tok.Prefix] = $tok.Number }
        }
        if ($rowOverflow) { continue }

        foreach ($rp in $rowMax.Keys) {
            if (-not $floors.ContainsKey($rp)) {
                $violations.Add(('BACKLOG-NEXTID FAIL: backlog has rows with prefix {1} but no matching next-ID floor: {0} (each row-id prefix must be tracked by a "next ID: {1}-NN" floor)' -f $rel, $rp)) | Out-Null
                continue
            }
            if ($floors[$rp] -le $rowMax[$rp]) {
                $violations.Add(('BACKLOG-NEXTID FAIL: backlog next-ID floor {1}-{2} is not above the max present {1} row id {1}-{3}: {0} (next ID must be strictly greater than every present row id of that prefix; id reuse/regression is forbidden)' -f $rel, $rp, $floors[$rp], $rowMax[$rp])) | Out-Null
            }
        }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Line ('scanned ProjectRoot {0}; found {1} incubation candidate folder(s)' -f $project, $incubationFolders.Count)
Write-Line 'SCOPE INFO: manually invoked deterministic diagnostic only; lifecycle hard gates = 0.'
Write-Line 'CHECKS INFO: E1/E2/E3, EN-2, rule_docs/DOCS-PURITY owner topology, BACKLOG-NEXTID floors, and Spec-template marker/heading diagnostics run only on their disclosed paths and shapes.'
Write-Line 'LIMITS INFO: same-owner non-default roles and eight-heading deviations are INFO; semantic admission, deleted-ID gaps, unscanned reference forms, lifecycle completion, and secret absence remain outside this checker.'

if ($violations.Count -gt 0) {
    foreach ($v in $violations) {
        Write-Line $v
    }
}

# SIBLING-MENTION advisory inventory (never FAILs): emitted after violations so
# a FAIL run still leads with its violations.
foreach ($smi in $siblingMentionInfos) {
    Write-Line $smi
}

foreach ($info in $diagnosticInfos) {
    Write-Line $info
}

Write-Line 'INCUBATION INFO: E1/E2/E3 cover only disclosed README discovery, canonical-path reference, and same-folder sibling subsets. They do not prove full semantic conformance or secret absence.'

if ($violations.Count -gt 0) {
    Write-Line ('FAIL ({0} deterministic diagnostic violation(s); this invocation is not a lifecycle hard gate)' -f $violations.Count)
    exit 1
}

Write-Line 'PASS (no deterministic diagnostic violations in the disclosed subset; not full lifecycle or safety proof)'
exit 0
