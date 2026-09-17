# Export freshness workflow adapted from Apogee Party Health Bars (MIT; see LICENSE).
[CmdletBinding()]
param(
    [string]$WowRoot = $env:WOW_ROOT,
    [string]$MetadataPath = (Join-Path $PSScriptRoot '../docs/wow-api-export.json'),
    [string]$TocPath = (Join-Path $PSScriptRoot '../ApogeeTank.toc'),
    [string]$Target = 'classicEra',
    [switch]$Record
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $WowRoot) { $WowRoot = 'C:/Program Files (x86)/World of Warcraft' }
$metadata = Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json
if ($metadata.schemaVersion -ne 1) { throw 'Unsupported export metadata schema.' }
$property = $metadata.targets.PSObject.Properties[$Target]
if (-not $property) { throw "Unknown export target '$Target'. Configure it only after verifying the client." }
$targetInfo = $property.Value

# Read named columns: the installation file also contains unrelated build data.
$lines = @(Get-Content -LiteralPath (Join-Path $WowRoot '.build.info'))
$headers = $lines[0].Split('|')
$productColumn = -1
$versionColumn = -1
for ($index = 0; $index -lt $headers.Count; $index++) {
    if ($headers[$index] -like 'Product!*') { $productColumn = $index }
    if ($headers[$index] -like 'Version!*') { $versionColumn = $index }
}
if ($productColumn -lt 0 -or $versionColumn -lt 0) { throw 'Build metadata lacks Product or Version columns.' }
$versions = @(foreach ($line in $lines | Select-Object -Skip 1) {
    $values = $line.Split('|')
    if ($values.Count -gt [Math]::Max($productColumn, $versionColumn) -and
        $values[$productColumn] -eq $targetInfo.product) { $values[$versionColumn] }
})
$versions = @($versions | Sort-Object -Unique)
if ($versions.Count -ne 1) { throw "Expected one installed build for '$Target'." }
$version = $versions[0]
if ($version -notmatch '^(\d+)\.(\d+)\.(\d+)\.\d+$') { throw 'Malformed installed client version.' }
$interface = [int]$Matches[1] * 10000 + [int]$Matches[2] * 100 + [int]$Matches[3]
$tocLines = @(Get-Content -LiteralPath $TocPath | Where-Object { $_ -match '^## Interface:' })
if ($tocLines.Count -ne 1) { throw 'Expected one TOC Interface line.' }
$tocInterfaces = ($tocLines[0] -replace '^## Interface:\s*', '').Split(',').Trim()
if ([string]$interface -notin $tocInterfaces) { throw "Installed interface $interface is not declared in the TOC." }

$clientRoot = Join-Path $WowRoot $targetInfo.clientDirectory
$executable = Get-Item -LiteralPath (Join-Path $clientRoot $targetInfo.executable)
$documentation = Join-Path $clientRoot 'BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated'
$requiredFiles = @('Blizzard_APIDocumentationGenerated.toc', 'UnitDocumentation.lua',
    'UnitAuraDocumentation.lua', 'NamePlateDocumentation.lua', 'SpellDocumentation.lua',
    'SpellSharedDocumentation.lua', 'RestrictedActionsDocumentation.lua')
if ($targetInfo.PSObject.Properties['requiredFiles']) {
    $requiredFiles += @($targetInfo.requiredFiles)
}
foreach ($name in $requiredFiles) {
    $file = Get-Item -LiteralPath (Join-Path $documentation $name)
    if ($file.LastWriteTimeUtc -lt $executable.LastWriteTimeUtc) {
        throw "Export '$name' predates the client. Refresh the interface export before recording it."
    }
}

if ($Record) {
    # Finish every validation before changing tracked metadata.
    $targetInfo.clientVersion = $version
    $targetInfo.interface = $interface
    $targetInfo.recordedOn = (Get-Date).ToString('yyyy-MM-dd')
    $json = ($metadata | ConvertTo-Json -Depth 6) -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($MetadataPath),
        $json + "`n", [System.Text.UTF8Encoding]::new($false))
} elseif ($targetInfo.clientVersion -ne $version -or $targetInfo.interface -ne $interface) {
    throw 'Installed build differs from the recorded export. Refresh the export, then run this script with -Record.'
}
Write-Host "API export checked: $Target, build $version, interface $interface."
