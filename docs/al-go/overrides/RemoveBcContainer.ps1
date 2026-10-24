# AL-Go "remove the build container" -> delete the BCDock env. Never let a build leak an env.
Param([Hashtable] $parameters)
. (Join-Path $PSScriptRoot '_bcdock.ps1')
$file = Get-BcDockStateFile
if (-not (Test-Path $file)) { Write-Host 'BCDock: no env recorded for this build; nothing to delete.'; return }
$buildEnv = Get-BuildEnv
Write-BcDockBanner "delete env $($buildEnv.name)"
Write-Host "Deleting BCDock env $($buildEnv.name)"
Invoke-BcDock env delete $buildEnv.id --force --wait | Out-Host
Remove-Item $file -Force
Remove-Item (Get-BcDockPublishedFile) -Force -ErrorAction SilentlyContinue
