#Requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    & dotnet build 'src/Lending.Database/Lending.Database.sqlproj' --configuration Release
    if ($LASTEXITCODE -ne 0) { throw 'SQL project build failed.' }
    $dacpac = Join-Path $repoRoot 'src/Lending.Database/bin/Release/Lending.Database.dacpac'
    if (-not (Test-Path $dacpac)) { throw 'Build did not produce the expected DACPAC.' }
    Write-Host "Built: $dacpac"
}
finally {
    Pop-Location
}
