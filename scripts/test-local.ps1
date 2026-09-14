[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$tankRepo = Split-Path -Parent $PSScriptRoot
Push-Location $tankRepo
try {
    $version = (& lua -v 2>&1 | Out-String)
    if ($version -notmatch 'Lua 5\.1\.') { throw 'Lua 5.1 is required.' }
    $toc = Get-Content -LiteralPath 'ApogeeTank.toc'
    if ($toc -notcontains '## Interface: 11509') { throw 'Expected Classic Era interface 11509.' }
    if ($toc -match '^## (SavedVariables:|Dependencies|RequiredDeps|OptionalDeps)') {
        throw 'No account-wide settings or other addon dependencies are allowed.'
    }
    if (@($toc | Where-Object { $_ -match '^## SavedVariablesPerCharacter:' }).Count -ne 1 -or
        $toc -notcontains '## SavedVariablesPerCharacter: ApogeeTankEffectsDB') {
        throw 'Only the character effect watch list may be persisted.'
    }
    foreach ($line in $toc) {
        if ($line -match '^[^#].*\.lua$' -and -not (Test-Path -LiteralPath $line)) {
            throw "Missing TOC source: $line"
        }
    }
    foreach ($file in Get-ChildItem -Recurse -Filter '*.lua' -File) {
        & luac -p $file.FullName
        if ($LASTEXITCODE -ne 0) { throw "Lua parse failed: $($file.Name)" }
    }
    foreach ($test in Get-ChildItem -LiteralPath 'tests' -Filter '*_spec.lua' -File | Sort-Object Name) {
        & lua $test.FullName
        if ($LASTEXITCODE -ne 0) { throw "Test failed: $($test.Name)" }
    }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Git whitespace validation failed.' }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Staged Git whitespace validation failed.' }
    # Include new files, which git diff does not examine before their first commit.
    foreach ($file in Get-ChildItem -Recurse -File | Where-Object Extension -in '.lua', '.md', '.toc', '.ps1') {
        if (Select-String -LiteralPath $file.FullName -Pattern '[\t ]+$' -Quiet) {
            throw "Trailing whitespace: $($file.FullName)"
        }
    }
    Write-Host 'All Apogee Tank local checks passed.'
}
finally { Pop-Location }
