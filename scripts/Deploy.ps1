#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Script', 'Publish')]
    [string] $Action = 'Script'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($env:LENDING_SQL_CONNECTION_STRING)) {
    throw 'Set LENDING_SQL_CONNECTION_STRING, including the target database name, before deploying.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    & (Join-Path $PSScriptRoot 'Build.ps1')
    & dotnet tool restore
    if ($LASTEXITCODE -ne 0) { throw 'SqlPackage tool restore failed.' }

    $dacpac = Join-Path $repoRoot 'src/Lending.Database/bin/Release/Lending.Database.dacpac'
    $sqlPackageArgs = @(
        "/Action:$Action"
        "/SourceFile:$dacpac"
        "/TargetConnectionString:$env:LENDING_SQL_CONNECTION_STRING"
        '/p:BlockOnPossibleDataLoss=True'
        '/p:DropObjectsNotInSource=False'
    )
    if ($Action -eq 'Script') {
        $artifactDirectory = Join-Path $repoRoot 'artifacts'
        New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
        $sqlPackageArgs += "/OutputPath:$(Join-Path $artifactDirectory 'deployment.sql')"
    }

    # Do not print the argument array: it contains the connection string.
    & dotnet tool run sqlpackage -- @sqlPackageArgs
    if ($LASTEXITCODE -ne 0) { throw "SqlPackage $Action failed." }
    if ($Action -eq 'Script') {
        Write-Host 'Generated artifacts/deployment.sql; no schema changes were applied.'
    }
}
finally {
    Pop-Location
}
