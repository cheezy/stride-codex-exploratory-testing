<#
.SYNOPSIS
    Structure smoke test for the stride-codex-exploratory-testing plugin (PowerShell twin).

.DESCRIPTION
    Asserts the plugin ships every file the Codex CLI edition requires: a
    valid manifest with the four Codex keys, all seven command-skills, all
    six doctrine skills, both agents, the three README-referenced fixtures,
    and the root docs (including AGENTS.md and both installers). Codex ships
    NO command files, so there is no commands/ check. A last section pins
    what the explorer card in agents/explorer.md says. JSON is parsed with
    ConvertFrom-Json — no network, no jq. Mirrors lib/test-structure.sh.

    Exit code: 0 if every check passes; 1 if any check fails.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PluginRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$script:Pass = 0
$script:Fail = 0

function Test-Ok([string]$msg) {
    $script:Pass++
    Write-Host ("  [PASS]  {0}" -f $msg)
}
function Test-Nope([string]$msg, [string]$detail = '') {
    $script:Fail++
    Write-Host ("  [FAIL]  {0}" -f $msg)
    if ($detail) { Write-Host ("          {0}" -f $detail) }
}

Write-Host "stride-codex-exploratory-testing structure smoke test"
Write-Host ("plugin root: {0}" -f $PluginRoot)
Write-Host ""

# --- Manifest --------------------------------------------------------------

$Manifest = Join-Path $PluginRoot '.codex-plugin/plugin.json'
if (Test-Path -LiteralPath $Manifest -PathType Leaf) {
    $parsed = $null
    $jsonOk = $false
    try {
        $raw = Get-Content -LiteralPath $Manifest -Raw
        $parsed = $raw | ConvertFrom-Json
        # ConvertFrom-Json returns $null WITHOUT throwing for empty / whitespace /
        # literal `null` content — treat that as invalid so this twin agrees with the
        # bash python3 json.load check instead of silently skipping the key check.
        if ($null -ne $parsed) { $jsonOk = $true }
    }
    catch {
        $jsonOk = $false
    }

    if ($jsonOk) {
        Test-Ok ".codex-plugin/plugin.json exists and is valid JSON"
        # A valid manifest must be a JSON object; a top-level array/scalar is rejected
        # (matches the bash isinstance(d, dict) guard).
        if ($parsed -is [pscustomobject]) {
            $missing = @()
            foreach ($k in @('name', 'description', 'version', 'skills')) {
                if (-not ($parsed.PSObject.Properties.Name -contains $k)) { $missing += $k }
            }
            if ($missing.Count -eq 0) {
                Test-Ok "plugin.json has the four Codex keys (name, description, version, skills)"
            }
            else {
                Test-Nope ("plugin.json is missing key(s): {0}" -f ($missing -join ', '))
            }
        }
        else {
            Test-Nope "plugin.json is not a JSON object (expected an object with the four Codex keys)"
        }
    }
    else {
        Test-Nope "plugin.json is not valid JSON (empty, null, or malformed)"
    }
}
else {
    Test-Nope ".codex-plugin/plugin.json not found" $Manifest
}

# --- Command-skills (Codex has no commands/; entry is skill activation) -----

$CommandSkills = @(
    'stride-exploratory-testing-charter',
    'stride-exploratory-testing-nightmare-headline',
    'stride-exploratory-testing-explore',
    'stride-exploratory-testing-recon',
    'stride-exploratory-testing-debrief',
    'stride-exploratory-testing-pair',
    'stride-exploratory-testing-harden'
)
foreach ($skill in $CommandSkills) {
    $p = Join-Path $PluginRoot ("skills/{0}/SKILL.md" -f $skill)
    if (Test-Path -LiteralPath $p -PathType Leaf) { Test-Ok ("skills/{0}/SKILL.md exists" -f $skill) }
    else { Test-Nope ("skills/{0}/SKILL.md is missing" -f $skill) }
}

# --- Doctrine skills --------------------------------------------------------

$DoctrineSkills = @('stride-exploratory-testing', 'chartering', 'heuristics', 'oracles', 'session', 'bug-advocacy')
foreach ($skill in $DoctrineSkills) {
    $p = Join-Path $PluginRoot ("skills/{0}/SKILL.md" -f $skill)
    if (Test-Path -LiteralPath $p -PathType Leaf) { Test-Ok ("skills/{0}/SKILL.md exists" -f $skill) }
    else { Test-Nope ("skills/{0}/SKILL.md is missing" -f $skill) }
}

# Count only real SKILL.md files at the Codex layout depth (skills/<name>/SKILL.md):
# 7 command-skills + 6 doctrine skills = 13. Fixed depth (not -Recurse) so this twin
# matches the bash `skills/*/SKILL.md` glob and ignores the .gitkeep placeholder.
$skillCount = @(Get-ChildItem -Path (Join-Path $PluginRoot 'skills/*/SKILL.md') -File -ErrorAction SilentlyContinue).Count
if ($skillCount -eq 13) { Test-Ok "exactly 13 SKILL.md files present (.gitkeep ignored)" }
else { Test-Nope ("expected 13 SKILL.md files, found {0}" -f $skillCount) }

# --- Agents (Codex: bare *.md files, no commands/ directory) -----------------

foreach ($agent in @('charter-generator', 'explorer')) {
    $p = Join-Path $PluginRoot ("agents/{0}.md" -f $agent)
    if (Test-Path -LiteralPath $p -PathType Leaf) { Test-Ok ("agents/{0}.md exists" -f $agent) }
    else { Test-Nope ("agents/{0}.md is missing" -f $agent) }
}

$agentCount = @(Get-ChildItem -Path (Join-Path $PluginRoot 'agents') -Filter '*.md' -File -ErrorAction SilentlyContinue).Count
if ($agentCount -eq 2) { Test-Ok "exactly 2 agent files present (.gitkeep ignored)" }
else { Test-Nope ("expected 2 agent files, found {0}" -f $agentCount) }

# Codex ships no command files: assert there is no commands/ directory.
if (Test-Path -LiteralPath (Join-Path $PluginRoot 'commands') -PathType Container) {
    Test-Nope "unexpected commands/ directory (Codex ships no command files)" (Join-Path $PluginRoot 'commands')
}
else {
    Test-Ok "no commands/ directory (correct for Codex)"
}

# --- Fixtures (referenced by README.md) ------------------------------------

foreach ($fixture in @('example-charters.md', 'example-session-sheet.md', 'example-debrief.md')) {
    $p = Join-Path $PluginRoot ("fixtures/{0}" -f $fixture)
    if (Test-Path -LiteralPath $p -PathType Leaf) { Test-Ok ("fixtures/{0} exists" -f $fixture) }
    else { Test-Nope ("fixtures/{0} is missing" -f $fixture) }
}

# --- Root docs and installers ----------------------------------------------

foreach ($doc in @('README.md', 'HEURISTICS.md', 'CHANGELOG.md', 'LICENSE', 'AGENTS.md', 'install.sh', 'install.ps1')) {
    $p = Join-Path $PluginRoot $doc
    if (Test-Path -LiteralPath $p -PathType Leaf) { Test-Ok ("{0} exists" -f $doc) }
    else { Test-Nope ("{0} is missing" -f $doc) }
}

# --- Content pins: explorer card -------------------------------------------
#
# The same checks as the content-pin section of test-structure.sh, with
# identical labels. agents/explorer.md carries an inline card with every
# rule the explorer needs to rate a bug and end a session, so a skill that
# fails to load costs nothing. The checks hold the card right after the
# safety boundary and under 4,096 bytes, tie its severity words to
# bug-advocacy's four levels and its stop rules to the stop_reason row, and
# keep the skill references path-free. Later tasks in the port append here.
# The files are only read, never executed.

function Read-Lines([string]$path) {
    # Split on LF only and keep any CR, so byte counts match awk | wc -c.
    $parts = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) -split "`n"
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($p in $parts) { $list.Add($p) }
    if ($list.Count -gt 0 -and $list[$list.Count - 1] -eq '') { $list.RemoveAt($list.Count - 1) }
    return ,$list
}

function Get-Ticked([string]$text, [string]$pattern) {
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($m in [regex]::Matches($text, $pattern)) { $out.Add($m.Groups[1].Value) }
    return ,$out
}

Write-Host ''
$Explorer = Join-Path $PluginRoot 'agents/explorer.md'
$Advocacy = Join-Path $PluginRoot 'skills/bug-advocacy/SKILL.md'

if ((Test-Path -LiteralPath $Explorer -PathType Leaf) -and (Test-Path -LiteralPath $Advocacy -PathType Leaf)) {
    $exLines  = Read-Lines $Explorer
    $advLines = Read-Lines $Advocacy

    # Markers: exactly one of each, start before end, each alone on its line.
    $mStart = 0; $mEnd = 0; $lStart = 0; $lEnd = 0; $exact = $true
    for ($i = 0; $i -lt $exLines.Count; $i++) {
        $line = $exLines[$i].TrimEnd([char]13)
        if ($line.Contains('explorer-card:start')) {
            $mStart++; if ($lStart -eq 0) { $lStart = $i + 1 }
            if ($line -cne '<!-- explorer-card:start -->') { $exact = $false }
        }
        if ($line.Contains('explorer-card:end')) {
            $mEnd++; if ($lEnd -eq 0) { $lEnd = $i + 1 }
            if ($line -cne '<!-- explorer-card:end -->') { $exact = $false }
        }
    }
    $cardOk = ($mStart -eq 1 -and $mEnd -eq 1 -and $lStart -lt $lEnd -and $exact)
    if ($cardOk) {
        Test-Ok 'explorer card has exactly one start and one end marker, in order'
    }
    else {
        Test-Nope 'explorer card markers are invalid' "start=$mStart end=$mEnd; need exactly one of each, start before end, each alone on its line"
    }

    $card = New-Object 'System.Collections.Generic.List[string]'
    if ($cardOk) { for ($i = $lStart - 1; $i -le $lEnd - 1; $i++) { $card.Add($exLines[$i]) } }
    $cardTrim = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in $card) { $cardTrim.Add($l.TrimEnd([char]13)) }

    # Position: the card is the first section after the safety boundary.
    $heads = New-Object 'System.Collections.Generic.List[object]'
    for ($i = 0; $i -lt $exLines.Count -and $heads.Count -lt 3; $i++) {
        $line = $exLines[$i].TrimEnd([char]13)
        if ($line.StartsWith('## ', [StringComparison]::Ordinal)) { $heads.Add(@(($i + 1), $line)) }
    }
    $posOk = $cardOk -and $heads.Count -eq 3 `
        -and $heads[0][1].StartsWith('## Safety boundary', [StringComparison]::Ordinal) `
        -and $heads[1][1].StartsWith('## Explorer card', [StringComparison]::Ordinal) `
        -and $heads[1][0] -eq ($lStart + 1) -and $lEnd -lt $heads[2][0]
    if ($posOk) {
        Test-Ok 'explorer card sits right after the safety boundary'
    }
    else {
        Test-Nope 'explorer card is not the first section after the safety boundary' "need '## Safety boundary', then the start marker with '## Explorer card' on the next line, then the end marker before the next section"
    }

    # Byte cap, measured as awk '/explorer-card:start/,/explorer-card:end/' | wc -c
    $cardBytes = 0
    foreach ($l in $card) { $cardBytes += [Text.Encoding]::UTF8.GetByteCount($l) + 1 }
    if ($cardBytes -ge 1 -and $cardBytes -le 4096) {
        Test-Ok 'explorer card is within 4096 bytes'
    }
    else {
        Test-Nope 'explorer card is outside 1-4096 bytes' "measured $cardBytes bytes"
    }

    # Severity: token line, rank line and ladder bullets each equal
    # bug-advocacy's four-levels table, in order.
    $table = New-Object 'System.Collections.Generic.List[string]'
    $inTable = $false
    $rank = ''
    foreach ($raw in $advLines) {
        $line = $raw.TrimEnd([char]13)
        if ($line.StartsWith('### The four levels', [StringComparison]::Ordinal)) { $inTable = $true; continue }
        if ($line.StartsWith('### ', [StringComparison]::Ordinal)) { $inTable = $false }
        if ($inTable) {
            $m = [regex]::Match($line, '^\| \*\*([A-Za-z]+)\*\* \|')
            if ($m.Success) { $table.Add($m.Groups[1].Value) }
        }
        if ($rank -eq '') {
            $m = [regex]::Match($line, 'Rank order is \*\*([A-Za-z >]+)\*\*')
            if ($m.Success) { $rank = ($m.Groups[1].Value -split ' > ') -join ' ' }
        }
    }
    $tableStr = $table -join ' '
    $cEnum = ''; $cRank = ''
    $ladder = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $cardTrim) {
        if ($line.StartsWith('Severity words: ', [StringComparison]::Ordinal) -and $cEnum -eq '') {
            $cEnum = (Get-Ticked $line '`([A-Za-z]+)`') -join ' '
        }
        if ($line.StartsWith('Severity order: ', [StringComparison]::Ordinal) -and $cRank -eq '') {
            $cRank = ($line.Substring(16) -split ' > ') -join ' '
        }
        $m = [regex]::Match($line, '^- \*\*([A-Za-z]+)\*\*: ')
        if ($m.Success) { $ladder.Add($m.Groups[1].Value) }
    }
    $cLadder = $ladder -join ' '
    if ($table.Count -eq 4 -and $rank -ceq $tableStr -and $cEnum -ceq $tableStr -and $cRank -ceq $tableStr -and $cLadder -ceq $tableStr) {
        Test-Ok "explorer card severity tokens, rank and ladder match bug-advocacy's four levels"
    }
    else {
        Test-Nope 'explorer card severity drifted from bug-advocacy' "table='$tableStr' rank='$rank' card tokens='$cEnum' card rank='$cRank' card ladder='$cLadder'"
    }

    # stop_reason: the card's stop values and the output contract's must be the same set.
    $cStops = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($line in $cardTrim) {
        $m = [regex]::Match($line, '^- `([a-z_]+)`: ')
        if ($m.Success) { [void]$cStops.Add($m.Groups[1].Value) }
    }
    $kStops = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $rowPrefix = '| `stop_reason` |'
    foreach ($raw in $exLines) {
        $line = $raw.TrimEnd([char]13)
        if ($line.StartsWith($rowPrefix, [StringComparison]::Ordinal)) {
            foreach ($v in (Get-Ticked $line.Substring($rowPrefix.Length) '`([a-z_]+)`')) { [void]$kStops.Add($v) }
        }
    }
    if ($cStops.Count -gt 0 -and $cStops.SetEquals($kStops)) {
        Test-Ok "explorer card stop rules name exactly the output contract's stop_reason values"
    }
    else {
        $onlyCard = @($cStops | Where-Object { -not $kStops.Contains($_) } | Sort-Object) -join ' '
        $onlyContract = @($kStops | Where-Object { -not $cStops.Contains($_) } | Sort-Object) -join ' '
        Test-Nope 'explorer card stop_reason values differ from the output contract' "in card only: [$onlyCard] in contract only: [$onlyContract]"
    }

    # RIMGEA mapped onto bugs[] fields, and the three oracle verdicts.
    $cardText = $cardTrim -join "`n"
    $missingMap = ''
    foreach ($needle in @('- Replicate:', '- Isolate, into `minimal_repro`:', '- Maximize, into `worst_observed`:',
                          '- Generalize, into `generalization`:', '- Externalize, into `stakeholder_impact`:',
                          '- And say it clearly:', 'Verdicts: Defect; Known-bad-but-expected (', '); Acceptable.')) {
        if (-not $cardText.Contains($needle)) { $missingMap += " [$needle]" }
    }
    if ($missingMap -eq '') {
        Test-Ok 'explorer card maps RIMGEA onto bugs[] fields and names the oracle verdicts'
    }
    else {
        Test-Nope 'explorer card is missing RIMGEA or oracle-verdict text' "missing:$missingMap"
    }

    # Severity rules past the ladder (a tie, the modifiers and how they
    # combine, likelihood, an unknown impact) and the three oracle kinds.
    $missingRules = ''
    foreach ($needle in @('Clauses at two levels both match: take the higher, for what you demonstrated only.',
                          'Reach (', 'Avoidability (', 'Persistence (', 'A single modifier changes nothing',
                          'two or more raise it by one level, never more', 'never lift one to Critical', 'Minor is the lowest',
                          'Likelihood plays no part in the level', 'never as Critical or High',
                          'open `stakeholder_impact` with "Provisional"',
                          'Kinds, tried in turn: Never/Always invariants (', '); consistency oracles (', '); approximations (')) {
        if (-not $cardText.Contains($needle)) { $missingRules += " [$needle]" }
    }
    if ($missingRules -eq '') {
        Test-Ok 'explorer card carries the tie, modifier, likelihood and unknown-impact rules and the three oracle kinds'
    }
    else {
        Test-Nope 'explorer card is missing severity or oracle rule text' "missing:$missingRules"
    }

    # Skill references. Codex gives a custom agent the skills its parent
    # session has, listed by name with each one's path; nothing documents a
    # skills/<name>/SKILL.md path resolving from the project directory, where
    # the agent runs. So such a path is refused anywhere in the file, and each
    # skill is named instead.
    $relRefs = 0
    foreach ($raw in $exLines) {
        if ([regex]::IsMatch($raw, 'skills/[a-z-]+/SKILL\.md')) { $relRefs++ }
    }
    if ($relRefs -eq 0) {
        Test-Ok 'agents/explorer.md names no skill by a skills/<name>/SKILL.md path'
    }
    else {
        Test-Nope 'agents/explorer.md names a skill by a skills/<name>/SKILL.md path' "$relRefs line(s); name the skill instead, since Codex documents no project-relative path to an installed skill"
    }

    $missingByName = ''
    foreach ($skill in @('heuristics', 'oracles', 'bug-advocacy', 'session')) {
        $pat = '- **`' + $skill + '`** (skill, by name)'
        $hits = 0
        foreach ($raw in $exLines) {
            if ($raw.TrimEnd([char]13).StartsWith($pat, [StringComparison]::Ordinal)) { $hits++ }
        }
        if ($hits -ne 1) { $missingByName += " $skill" }
    }
    if ($missingByName -eq '') {
        Test-Ok 'explorer skill references name each skill for Codex to find by name'
    }
    else {
        Test-Nope 'explorer skill reference not in by-name form' "for:$missingByName"
    }
}
else {
    Test-Nope 'explorer card checks need agents/explorer.md and skills/bug-advocacy/SKILL.md'
}

# --- summary ----------------------------------------------------------------

Write-Host ""
Write-Host ("{0} passed, {1} failed" -f $script:Pass, $script:Fail)
if ($script:Fail -gt 0) { exit 1 }
exit 0
