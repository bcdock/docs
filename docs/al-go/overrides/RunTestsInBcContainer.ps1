# AL-Go "run the tests of one test app" -> altool runtests against the BCDock env, results as
# JUnit appended to the file AL-Go names. Returns $true only if every test ran and passed.
Param([Hashtable] $parameters)
. (Join-Path $PSScriptRoot '_bcdock.ps1')
$buildEnv = Get-BuildEnv
$conn = Get-AlToolConnectionArgs $buildEnv
Write-BcDockBanner "run tests of $($parameters.appName) on $($buildEnv.name)"

# The test app's .app: AL-Go leaves compiled apps under .output, which Linux treats as hidden (-Force).
# Only .app files with test codeunits; a .app that cannot be read (symbols, runtime packages) is skipped.
$appFile = Get-ChildItem -Path $env:GITHUB_WORKSPACE -Recurse -Force -Filter '*.app' |
    Where-Object { $_.Name -like "*$($parameters.appName)*" } |
    Where-Object { try { @(Get-AppTestCodeunits -AppFile $_.FullName).Count -gt 0 } catch { $false } } |
    Select-Object -First 1
if (-not $appFile) { throw "No compiled .app found for test app '$($parameters.appName)'" }
$testCodeunits = @(Get-AppTestCodeunits -AppFile $appFile.FullName)
$codeunits = @($testCodeunits | ForEach-Object { $_.Id })
$codeunitNames = @{}
foreach ($cu in $testCodeunits) { $codeunitNames[$cu.Id] = $cu.Name }
Write-Host "Running test codeunits $($codeunits -join ', ') of $($parameters.appName) on $($buildEnv.name)"

$groups = Join-Path ([IO.Path]::GetTempPath()) "bcdock-testgroups-$([guid]::NewGuid()).json"
# -InputObject keeps a one-element list a JSON array on Windows PowerShell 5.1 too (no -AsArray there).
ConvertTo-Json -InputObject @($codeunits | ForEach-Object { @{ codeunitId = $_ } }) | Set-Content $groups
# Built up front: an if/else that yields @() leaves $null, which reaches altool as an empty argument.
$companyArgs = @()
if ($parameters.companyName) { $companyArgs = @('--company', $parameters.companyName) }
$errFile = Join-Path ([IO.Path]::GetTempPath()) "bcdock-runtests-$([guid]::NewGuid()).err"
$raw = Invoke-AlTool runtests --testgroups $groups @conn @companyArgs 2>$errFile
try { $run = ($raw -join "`n") | ConvertFrom-Json }
catch {
    # Not JSON means altool did not run the tests (it prints its help on a bad argument): show why.
    Write-Host 'altool runtests did not return JSON. stdout:'; @($raw) | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
    Write-Host 'stderr:'; Get-Content $errFile -ErrorAction SilentlyContinue | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
    throw
}

# Per-test lines and GitHub annotations in the build log, as BcContainerHelper's test runner prints them.
$gha = if ($parameters.GitHubActions) { [string]$parameters.GitHubActions } else { 'no' }
Write-AlToolResultsToHost -Runs @($run) -CodeunitNames $codeunitNames -GitHubActions $gha

$resultsFile = $parameters.JUnitResultFileName
$allPassed = Write-AlToolResultsAsJUnit -Runs @($run) -ResultsFile $resultsFile -AppName $parameters.appName -ExtensionId ([string]$parameters.extensionId) `
    -CodeunitNames $codeunitNames -Append:([bool]$parameters.AppendToJUnitResultFile)
Write-Host ("{0}: {1}" -f $parameters.appName, $(if ($allPassed) { 'all tests passed' } else { 'TESTS FAILED' }))
if ($parameters.returnTrueIfAllPassed) { return $allPassed }
