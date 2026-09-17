[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'check-wow-api-export.ps1'
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('apogee-tank-export-' + [guid]::NewGuid())
$fixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
if (-not $fixtureRoot.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Fixture directory must stay inside the temporary directory.'
}
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
try {
    $client = Join-Path $fixtureRoot '_classic_era_'
    $docs = Join-Path $client 'BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated'
    New-Item -ItemType Directory -Path $docs -Force | Out-Null
    $exe = Join-Path $client 'WowClassic.exe'
    Set-Content -LiteralPath $exe -Value 'fixture'
    (Get-Item -LiteralPath $exe).LastWriteTimeUtc = [datetime]::UtcNow.AddHours(-2)
    $names = @('Blizzard_APIDocumentationGenerated.toc', 'UnitDocumentation.lua',
        'UnitAuraDocumentation.lua', 'NamePlateDocumentation.lua', 'SpellDocumentation.lua',
        'SpellSharedDocumentation.lua', 'RestrictedActionsDocumentation.lua')
    foreach ($name in $names) { Set-Content -LiteralPath (Join-Path $docs $name) -Value 'fixture' }
    $build = Join-Path $fixtureRoot '.build.info'
    Set-Content -LiteralPath $build -Value @('Version!STRING:0|Product!STRING:0', '1.15.9.69722|wow_classic_era')
    $metadata = Join-Path $fixtureRoot 'metadata.json'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../docs/wow-api-export.json') -Destination $metadata
    $toc = Join-Path $fixtureRoot 'test.toc'
    Set-Content -LiteralPath $toc -Value '## Interface: 11509'
    $arguments = @{ WowRoot = $fixtureRoot; MetadataPath = $metadata; TocPath = $toc }
    function ExpectFailure([string]$Message, [scriptblock]$Action, [string]$Pattern) {
        $caught = $null
        try { & $Action } catch { $caught = $_.Exception.Message }
        if (-not $caught -or $caught -notlike $Pattern) { throw "$Message (received: $caught)" }
    }
    & $checker @arguments
    ExpectFailure 'Unknown client accepted' { & $checker @arguments -Target forever } '*Unknown export target*'
    $betaClient = Join-Path $fixtureRoot '_classic_beta_'
    $betaDocs = Join-Path $betaClient 'BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated'
    New-Item -ItemType Directory -Path $betaDocs -Force | Out-Null
    $betaExe = Join-Path $betaClient 'WowB.exe'
    Set-Content -LiteralPath $betaExe -Value 'fixture'
    (Get-Item -LiteralPath $betaExe).LastWriteTimeUtc = [datetime]::UtcNow.AddHours(-2)
    $betaMetadata = (Get-Content -LiteralPath $metadata -Raw | ConvertFrom-Json).targets.foreverBeta
    foreach ($name in ($names + @($betaMetadata.requiredFiles))) {
        Set-Content -LiteralPath (Join-Path $betaDocs $name) -Value 'fixture'
    }
    Set-Content -LiteralPath $build -Value @('Version!STRING:0|Product!STRING:0',
        '1.15.9.69722|wow_classic_era', '1.60.1.69893|wow_classic_beta')
    ExpectFailure 'Beta TOC mismatch accepted' { & $checker @arguments -Target foreverBeta } '*not declared in the TOC*'
    Set-Content -LiteralPath $toc -Value '## Interface: 11509, 16001'
    & $checker @arguments -Target foreverBeta
    $betaMarker = Get-Item -LiteralPath (Join-Path $betaDocs 'SimpleStatusBarAPIDocumentation.lua')
    $betaMarker.LastWriteTimeUtc = [datetime]::UtcNow.AddDays(-1)
    $betaBefore = Get-Content -LiteralPath $metadata -Raw
    ExpectFailure 'Stale beta export recorded' { & $checker @arguments -Target foreverBeta -Record } '*predates the client*'
    if ((Get-Content -LiteralPath $metadata -Raw) -ne $betaBefore) { throw 'Failed beta recording modified metadata.' }
    $betaMarker.LastWriteTimeUtc = [datetime]::UtcNow
    & $checker @arguments -Target foreverBeta -Record
    & $checker @arguments -Target foreverBeta
    Set-Content -LiteralPath $build -Value @('Version!STRING:0|Product!STRING:0', '1.15.9.99999|wow_classic_era')
    ExpectFailure 'Changed build accepted' { & $checker @arguments } '*Installed build differs*'
    $before = Get-Content -LiteralPath $metadata -Raw
    $marker = Get-Item -LiteralPath (Join-Path $docs $names[0])
    $marker.LastWriteTimeUtc = [datetime]::UtcNow.AddDays(-1)
    ExpectFailure 'Stale export recorded' { & $checker @arguments -Record } '*predates the client*'
    if ((Get-Content -LiteralPath $metadata -Raw) -ne $before) { throw 'Failed recording modified metadata.' }
    $marker.LastWriteTimeUtc = [datetime]::UtcNow
    & $checker @arguments -Record
    & $checker @arguments
    $saved = Get-Content -LiteralPath $metadata -Raw | ConvertFrom-Json
    if ($saved.targets.classicEra.clientVersion -ne '1.15.9.99999') { throw 'Recording did not update build.' }
    Set-Content -LiteralPath $toc -Value '## Interface: 99999'
    ExpectFailure 'TOC mismatch accepted' { & $checker @arguments } '*not declared in the TOC*'
    Set-Content -LiteralPath $toc -Value '## Interface: 11509'
    Remove-Item -LiteralPath (Join-Path $docs 'SpellDocumentation.lua')
    ExpectFailure 'Missing documentation accepted' { & $checker @arguments } '*does not exist*'
    Write-Host 'Export checker regression tests passed.'
} finally {
    # This exact, verified directory was created exclusively for these fixtures.
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
