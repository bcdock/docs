# AL-Go "create the build container" -> create a BCDock environment for this build.
Param([Hashtable] $parameters)
. (Join-Path $PSScriptRoot '_bcdock.ps1')

$artifact = ConvertFrom-ArtifactUrl $parameters.artifactUrl
# The env goes to your BCDock company's default region (bcdock companies set-location), unless
# BCDOCK_REGION names another. The default is read with `bcdock me show` and passed explicitly.
$region = $env:BCDOCK_REGION
if (-not $region) {
    # stdout is the JSON; stderr (progress, errors) is kept apart so it cannot break the parse.
    $meErr = Join-Path ([IO.Path]::GetTempPath()) "bcdock-me-$([guid]::NewGuid()).err"
    $meJson = & bcdock me show --output json 2>$meErr
    $meExit = $LASTEXITCODE
    $why = Get-Content $meErr -ErrorAction SilentlyContinue | Select-Object -Last 1
    Remove-Item $meErr -ErrorAction SilentlyContinue
    if ($meExit -ne 0) {
        # Most often a wrong or revoked key: say so, not "set a region".
        throw "BCDock: could not read your account with BCDOCK_TOKEN (bcdock me show exit $($meExit): $why). Check the BCDOCK_TOKEN repo secret."
    }
    $region = ($meJson -join "`n" | ConvertFrom-Json).azureRegion
}
if (-not $region) { throw 'BCDock: no region for the build env. Set your company default region (bcdock companies set-location <country> --region <azure-region>).' }
$regionArgs = @('--region', $region)
$regionText = $region
# Windows PowerShell 5.1 compatible (AL-Go may load overrides there): no ?? operator.
$runId = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { 'local' }
$attempt = if ($env:GITHUB_RUN_ATTEMPT) { $env:GITHUB_RUN_ATTEMPT } else { '1' }
# Every Build job of a run (one per project and build mode) creates its own env, so the name carries a
# random suffix, and every call after create addresses the env by its id, never by name.
$suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)
$name = ("algo-{0}-{1}-{2}" -f $runId, $attempt, $suffix).ToLowerInvariant()
Write-BcDockBanner "create env $name (BC $($artifact.MajorMinor) $($artifact.Country))"
Write-Host "Creating BCDock env ${name}: BC $($artifact.MajorMinor) (newest ready build; AL-Go's artifact is $($artifact.Version)) $($artifact.Country) $($artifact.Type) in $regionText"

# Optional arguments are built as arrays up front: `$x = if (...) { @(...) } else { @() }` leaves $x
# $null, which a splat through Invoke-BcDock/Invoke-AlTool passes as an EMPTY argument.
$typeArgs = @()
if ($artifact.Type -eq 'onprem') { $typeArgs = @('--type', 'onprem') }
$created = Invoke-BcDock env create --name $name --version $artifact.MajorMinor --country $artifact.Country @regionArgs @typeArgs --output json | ConvertFrom-Json
$state = @{ name = $name; id = $created.id; bcMajor = $artifact.Major; type = $artifact.Type }
Remove-Item (Get-BcDockPublishedFile) -Force -ErrorAction SilentlyContinue

# AL-Go calls RemoveBcContainer only after this script returns, so a failure from here on must delete
# the env itself, or the build leaves it running.
try {
    # Wait until it is running. bcdock 0.5.9+ retries a passing failure (a BCDock deploy in progress) inside
    # the wait itself, so any non-zero exit here is final.
    Invoke-BcDock env wait $created.id --status running --timeout 45m | Out-Host
    $env_ = Invoke-BcDock env get $created.id --output json | ConvertFrom-Json
    $state.devEndpointUrl = $env_.devEndpointUrl
    $state | ConvertTo-Json | Set-Content (Get-BcDockStateFile)
}
catch {
    Write-Host "Deleting BCDock env $name after a failed create: $($_.Exception.Message)"
    & bcdock env delete $created.id --force | Out-Host
    throw
}

# altool for this BC major, from NuGet (18.x drives BC 28-29; 30.x drives BC 30+).
$ver = Get-AlToolPackageVersion $artifact.Major
$prerelease = @()
if ($ver -like '*-*') { $prerelease = @('--prerelease') }
dotnet tool update --global Microsoft.Dynamics.BusinessCentral.Development.Tools --version $ver @prerelease | Out-Host
Write-Host "BCDock env $name is running: $($env_.devEndpointUrl)"
