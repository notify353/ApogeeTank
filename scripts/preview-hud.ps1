[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$previousCapture = $env:APOGEE_UI_CAPTURE
$repo = Split-Path -Parent $PSScriptRoot
$destination = [IO.Path]::GetFullPath($OutputPath)
$capture = [IO.Path]::ChangeExtension($destination, '.json')
Push-Location $repo
try {
    $env:APOGEE_UI_CAPTURE = $capture
    & lua tests/runtime_spec.lua
    if ($LASTEXITCODE -ne 0) { throw 'Runtime capture failed.' }
    $template = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'hud-preview.html')
    $data = (Get-Content -Raw -LiteralPath $capture).Replace('<', '\u003c')
    [IO.File]::WriteAllText($destination, $template.Replace('__CAPTURE_DATA__', $data))
    Write-Host "Preview: $destination"
}
finally {
    $env:APOGEE_UI_CAPTURE = $previousCapture
    Pop-Location
}
